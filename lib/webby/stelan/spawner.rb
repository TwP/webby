# $Id$

require 'rbconfig'
require 'thread'
require 'tempfile'

# == Synopsis
#
# A class for spawning child processes and ensuring those children continue
# running.
#
# == Details
#
# When a spawner is created it is given the command to run in a child
# process. This child process has +stdin+, +stdout+, and +stderr+ redirected
# to +/dev/null+ (this works even on Windows). When the child dies for any
# reason, the spawner will restart a new child process in the exact same
# manner as the original.
#
class Spawner

  @dev_null = test(?e, "/dev/null") ? "/dev/null" : "NUL:"

  c = ::Config::CONFIG
  ruby = File.join(c['bindir'], c['ruby_install_name']) << c['EXEEXT']
  @ruby = if    system('%s -e exit' % ruby) then ruby
          elsif system('ruby -e exit')      then 'ruby' 
          else  warn 'no ruby in PATH/CONFIG'
          end

  class << self
    attr_reader :ruby
    attr_reader :dev_null

    def finalizer( cids )
      pid = $$
      lambda do
        break unless pid == $$
        cids.kill 'TERM', :all
      end  # lambda
    end  # finalizer
  end

  # call-seq:
  #    Spawner.new( command, *args, opts = {} )
  #
  # Creates a new spawner that will execute the given external _command_ in
  # a sub-process. The calling semantics of <code>Kernel::exec</code> are
  # used to execute the _command_. Any number of optional _args_ can be
  # passed to the _command_.
  #
  # Available options:
  #
  #    :spawn   => the number of child processes to spawn
  #    :pause   => wait time (in seconds) before respawning after termination
  #    :ruby    => the Ruby interpreter to use when spawning children
  #    :env     => a hash for the child process environment
  #    :stdin   => stdin child processes will read from
  #    :stdout  => stdout child processes will write to
  #    :stderr  => stderr child processes will write to
  #
  # The <code>:env</code> option is used to add environemnt variables to
  # child processes when they are spawned.
  #
  # *Note:* all spawned child processes will use the same stdin, stdout, and
  # stderr if they are given in the options. Otherwise they all default to
  # <code>/dev/null</code> on *NIX and <code>NUL:</code> on Windows.
  #
  def initialize( *args )
    config = {
      :ruby => self.class.ruby,
      :spawn => 1,
      :pause => 0,
      :stdin => self.class.dev_null,
      :stdout => self.class.dev_null,
      :stderr => self.class.dev_null
    }
    config.merge! args.pop if Hash === args.last
    config[:argv] = args

    raise ArgumentError, 'wrong number of arguments' if args.empty?

    @stop = true
    @cids = []
    @group = ThreadGroup.new

    @spawn = config.delete(:spawn)
    @pause = config.delete(:pause)
    @ruby = config.delete(:ruby)

    @tmp = child_program(config)

    class << @cids
      # call-seq:
      #    sync {block}
      #
      # Executes the given block in a synchronized fashion -- i.e. only a
      # single thread can execute at a time. Uses Mutex under the hood.
      #
      def sync(&b) 
        @mutex ||= Mutex.new
        @mutex.synchronize(&b)
      end

      # call-seq:
      #    kill( signal, num )     => number killed
      #    kill( signal, :all )    => number killed
      #
      # Send the _signal_ to a given _num_ of child processes or all child
      # processes if <code>:all</code> is given instead of a number. Returns
      # the number of child processes killed.
      #
      def kill( signal, arg )
        return if empty?

        ary = sync do
                case arg
                when :all: self.dup
                when Integer: self.slice(0,arg)
                else raise ArgumentError end
              end

        ary.each do |cid|
          begin
            Process.kill(signal, cid)
          rescue SystemCallError
            sync {delete cid}
          end
        end
        ary.length
      end  # def kill
    end  # class << @cids

  end  # def initialize

  attr_reader :spawn
  attr_accessor :pause

  # call-seq:
  #    spawner.spawn = num
  #
  # Set the number of child processes to spawn. If the new spawn number is
  # less than the current number, then spawner threads will die 
  #
  def spawn=( num )
    num = num.abs
    diff, @spawn = num - @spawn, num
    return unless running?

    if diff > 0
      diff.times {_spawn}
    elsif diff < 0
      @cids.kill 'TERM', diff.abs
    end
  end

  # call-seq:
  #    start    => self
  #
  # Spawn the sub-processes.
  #
  def start
    return self if running?
    @stop = false

    @cleanup = Spawner.finalizer(@cids)
    ObjectSpace.define_finalizer(self, @cleanup)

    @spawn.times {_spawn}
    self
  end

  # call-seq:
  #    stop( timeout = 5 )    => self
  #
  # Stop any spawned sub-processes.
  #
  def stop( timeout = 5 )
    return self unless running?
    @stop = true

    @cleanup.call
    ObjectSpace.undefine_finalizer(self)

    # the cleanup call sends SIGTERM to all the child processes
    # however, some might still be hanging around, so we are going to wait
    # for a timeout interval and then send a SIGKILL to any remaining child
    # processes
    nap_time = 0.05 * timeout   # sleep for 5% of the timeout interval
    timeout = Time.now + timeout

    until @cids.empty?
      sleep nap_time
      unless Time.now < timeout
        @cids.kill 'KILL', :all
        @cids.clear
        @group.list.each {|t| t.kill}
        break
      end
    end

    self
  end

  # call-seq:
  #    restart( timeout = 5 )
  #
  def restart( timeout = 5 )
    stop( timeout )
    start
  end

  # call-seq:
  #    running?
  #
  # Returns +true+ if the spawner is currently running; returns +false+
  # otherwise.
  #
  def running?
    !@stop
  end

  # call-seq:
  #    join( timeout = nil )    => spawner or nil
  #
  # The calling thread will suspend execution until all child processes have
  # been stopped. Does not return until all spawner threads have exited (the
  # child processes have been stopped) or until _timeout seconds have
  # passed. If the timeout expires +nil+ will be returned; otherwise the
  # spawner is returned.
  #
  def join( limit = nil )
    loop do
      t = @group.list.first
      break if t.nil?
      return nil unless t.join(limit)
    end
    self
  end


  private

  # call-seq:
  #    _spawn    => thread
  #
  # Creates a thread that will spawn the sub-process via
  # <code>IO::popen</code>. If the sub-process terminates, it will be
  # respawned until the +stop+ message is sent to this spawner.
  #
  # If an Exception is encountered during the spawning process, a message
  # will be printed to stderr and the thread will exit.
  #
  def _spawn
    t = Thread.new do
          catch(:die) do
            loop do
              begin
                io = IO.popen("#{@ruby} #{@tmp.path}", 'r')
                cid = io.gets.to_i

                @cids.sync {@cids << cid} if cid > 0
                Process.wait cid
              rescue Exception => e
                STDERR.puts e.inspect
                STDERR.puts e.backtrace.join("\n")
                throw :die
              ensure
                io.close rescue nil
                @cids.sync {
                  @cids.delete cid
                  throw :die unless @cids.length < @spawn
                }
              end

              throw :die if @stop
              sleep @pause

            end  # loop
          end  # catch(:die)
        end  # Thread.new

    @group.add t
    t
  end

  # call-seq:
  #    child_program( config )    => tempfile
  #
  # Creates a child Ruby program based on the given _config_ hash. The
  # following hash keys are used:
  #
  #    :argv    => command and arguments passed to <code>Kernel::exec</code>
  #    :env     => environment variables for the child process
  #    :cwd     => the current working directory to use for the child process
  #    :stdin   => stdin the child process will read from
  #    :stdout  => stdout the child process will write to
  #    :stderr  => stderr the child process will write to
  #
  def child_program( config )
    config = Marshal.dump(config)

    tmp = Tempfile.new(self.class.name.downcase)
    tmp.write <<-PROG
      begin
        config = Marshal.load(#{config.inspect})

        argv = config[:argv]
        env = config[:env]
        cwd = config[:cwd]
        stdin = config[:stdin]
        stdout = config[:stdout]
        stderr = config[:stderr]

        Dir.chdir cwd if cwd
        env.each {|k,v| ENV[k.to_s] = v.to_s} if env
      rescue Exception => e
        STDERR.warn e
        abort
      end

      STDOUT.puts Process.pid
      STDOUT.flush

      STDIN.reopen stdin
      STDOUT.reopen stdout
      STDERR.reopen stderr

      exec *argv
    PROG

    tmp.close
    tmp
  end
end  # class Spawner

# EOF
