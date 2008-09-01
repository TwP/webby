require 'optparse'
require 'rake'

module Webby::Apps

class Main

  # Create a new instance of Main, and run the +webby+ application given the
  # command line _args_.
  #
  def self.run( args )
    self.new.run args
  end

  # Create a new Main webby object for building websites.
  #
  def initialize
    @stdout = $stdout
  end

  # Runs the main webby application. The command line arguments are passed
  # in to this method as an array of strings. The command line arguments are
  # parsed to figure out which rake task to invoke.
  #
  def run( args )
    args = args.dup

    parse args
    init args
    rake
  end

  # Parse the command line _args_ for options and commands to invoke.
  #
  def parse( args )
    opts = OptionParser.new
    opts.banner = 'Usage: webby [options] target [target args]'

    opts.separator ''
    opts.on('-D', '--describe [PATTERN]', 'describe the tasks (matching optional PATTERN), then exit') {|pattern| app.do_option('--describe', pattern)}
    opts.on('-P', '--prereqs', 'display the tasks and dependencies, then exit') {app.do_option('--prereqs', nil)}
    opts.on('-T', '--tasks [PATTERN]', 'display the tasks (matching optional PATTERN) with descriptions, then exit') {|pattern| app.do_option('--tasks', pattern)}
    opts.on('-t', '--trace', 'turn on invoke/execute tracing, enable full backtrace') {app.do_option('--trace', nil)}

    opts.separator ''
    opts.separator 'common options:'

    opts.on_tail( '-h', '--help', 'show this message' ) do
      @stdout.puts opts
      exit
    end
    opts.on_tail( '--version', 'show version' ) do
      @stdout.puts "Webby #{::Webby::VERSION}"
      exit
    end

    opts.parse! args

    ARGV.replace Array(args.shift)
    args.delete_if do |arg|
      if %r/^[A-Z_]+=/ =~ arg
        ARGV << arg
        next true
      end
      false
    end

    args
  end

  # Initialize the Rake application object and load the core rake tasks, the
  # site specific rake tasks, and the site specific ruby code. Any extra
  # command line arguments are converted into a page name and directory that
  # might get created (depending upon the task invoked).
  #
  def init( args )
    # Make sure we're in a folder with a Sitefile
    app.do_option('--rakefile', 'Sitefile')
    app.do_option('--nosearch', nil)
    app.do_option('--silent', nil)

    unless app.have_rakefile
      raise RuntimeError, "Sitefile not found"
    end

    import_default_tasks
    import_website_tasks
    require_lib_files
    capture_command_line_args(args)
    args
  end

  # Execute the rake command.
  #
  def rake
    app.init 'webby'
    app.load_rakefile
    app.top_level
  end

  # Return the Rake application object.
  #
  def app
    Rake.application
  end

  # Search for the "Sitefile" starting in the current directory and working
  # upwards through the filesystem until the root of the filesystem is
  # reached. If a "Sitefile" is not found, a RuntimeError is raised.
  #
  def find_sitefile
    here = Dir.pwd
    while ! app.have_rakefile
      Dir.chdir("..")
      if Dir.pwd == here || options.nosearch
        fail "No Sitefile found"
      end
      here = Dir.pwd
    end
  end

  def import_default_tasks
    Dir.glob(::Webby.libpath(%w[webby tasks *.rake])).sort.each {|fn| import fn}
  end

  def import_website_tasks
    Dir.glob(::File.join(%w[tasks *.rake])).sort.each {|fn| import fn}
  end

  def require_lib_files
    Dir.glob(::File.join(%w[lib ** *.rb])).sort.each {|fn| require fn}
  end

  def capture_command_line_args(args)
    args = OpenStruct.new(:raw => args)

    if args.raw.size > 1
      ::Webby.deprecated "multiple arguments used for page title",
                         "please quote the page title"
    end

    dashed = args.raw.join('-').downcase
    spaced = args.raw.join(' ')
    dir = ::File.dirname(dashed)

    args.dir   = ('.' == dir ? '' : dir)
    args.slug  = ::Webby::Resources.basename(dashed).to_url
    args.title = ::Webby::Resources.basename(spaced).titlecase

    # page should be dir/slug without leading /
    args.page  = ::File.join(args.dir, args.slug).gsub(/^\//, '')

    ext = ::File.extname(dashed)
    args.page << ext unless ext.empty?

    ::Webby.site.args = args
    Object.const_set(:SITE, Webby.site)
    args
  end

end  # class Main
end  # module Webby::Apps

# :stopdoc:
# Monkey patches so that rake displays the correct application name in the
# help messages.
#
class Rake::Application
  def display_prerequisites
    tasks.each do |t|
      puts "#{name} #{t.name}"
      t.prerequisites.each { |pre| puts "    #{pre}" }
    end
  end

  def display_tasks_and_comments
    displayable_tasks = tasks.select { |t|
      t.comment && t.name =~ options.show_task_pattern
    }
    if options.full_description
      displayable_tasks.each do |t|
        puts "#{name} #{t.name_with_args}"
        t.full_comment.split("\n").each do |line|
          puts "    #{line}"
        end
        puts
      end
    else
      width = displayable_tasks.collect { |t| t.name_with_args.length }.max || 10
      max_column = 80 - name.size - width - 7
      displayable_tasks.each do |t|
        printf "#{name} %-#{width}s  # %s\n",
          t.name_with_args, truncate(t.comment, max_column)
      end
    end
  end

  # Provide standard execption handling for the given block.
  def standard_exception_handling
    begin
      yield
    rescue SystemExit => ex
      # Exit silently with current status
      exit(ex.status)
    rescue SystemExit, GetoptLong::InvalidOption => ex
      # Exit silently
      exit(1)
    rescue Exception => ex
      # Exit with error message
      $stderr.puts "webby aborted!"
      $stderr.puts ex.message
      if options.trace
        $stderr.puts ex.backtrace.join("\n")
      else
        $stderr.puts ex.backtrace.find {|str| str =~ /#{@rakefile}/ } || ""
        $stderr.puts "(See full trace by running task with --trace)"
      end
      exit(1)
    end
  end
end  # class Rake::Application
# :startdoc:

# EOF
