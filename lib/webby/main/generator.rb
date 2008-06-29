require 'fileutils'
require 'optparse'

class Webby::Main

# webby gen template site  => creates the tmplate
# webby gen -h / --help
# webby gen       => same as --help
#

class Generator

  WINDOWS = %r/djgpp|(cyg|ms|bcc)win|mingw/ =~ RUBY_PLATFORM    # :nodoc:

  attr_accessor :template, :site
  attr_reader :options

  # Initialize a new generator object.
  #
  def initialize
    @options = {}
    @site = @template = nil
    @stdout, @stdin = $stdout, $stdin
  end

  # Run the generator executing the commands specified by the user on the
  # command line.
  #
  def run( args )
    parse args
    create_site
  end

  # Parse out the command line options found in the args array.
  #
  def parse( args )
    opts = OptionParser.new
    opts.banner = 'Usage: webby gen [options] template site'

    opts.separator ''
    opts.on('-f', '--force',
            'overwrite files that already exist') {options[:collision] = :force}
    opts.on('-s', '--skip',
            'skip files that already exist') {options[:collision] = :skip}
    opts.on('-u', '--update',
            'update rake tasks for the site') {options[:update] = true}
    opts.on('-p', '--pretend',
            'run but do not make any changes') {options[:pretend] = true}

    opts.separator ''
    opts.on('-t', '--templates', 'list available templates') {
      @stdout.puts opts
      ary = templates.map {|t| ::File.basename(t)}
      ary.delete 'webby'
      @stdout.puts "\nAvailable Templates"
      @stdout.puts "    #{ary.join(', ')}"
      @stdout.puts
      exit
    }

    opts.separator ''
    opts.separator 'common options:'

    opts.on_tail( '-h', '--help', 'show this message' ) {@stdout.puts opts; exit}
    opts.on_tail( '--version', 'show version' ) do
      @stdout.puts "Webby #{::Webby::VERSION}"
      exit
    end

    # parse the command line arguments
    opts.parse! args
    tmpl, @site = args

    if @site.nil? or tmpl.nil?
      @stdout.puts opts
      exit 1
    end

    templates.each {|t| self.template = t if t =~ %r/\/#{tmpl}$/}
    if @template.nil?
      @stdout.puts opts
      abort "Could not find template '#{tmpl}'"
    end

    nil
  end

  # Returns +true+ if we are only going to pretend to do something. All the
  # output messages will be written, but no changes will be made on the
  # disc.
  #
  def pretend?
    options[:pretend] == true
  end

  # Returns an array of available site templates.
  #
  def templates
    Dir.glob(::Webby.path('examples') / '*').sort
  end

  # Create the site from the template specified by the user.
  #
  def create_site
    files = site_files

    # in update mode we only want to update the tasks directory
    if options[:update]
      FileUtils.mkdir_p site unless pretend?
      mkdir 'tasks'
      files['tasks'].sort.each {|file| cp file}
    else
      dirs = files.keys.concat %w[content layouts lib tasks templates]
      dirs.sort!
      dirs.uniq!

      # create the directories first
      dirs.each do |dir|
        next if dir =~ %r/^output\/.*$/
        mkdir dir
      end

      # and the create the files under each directory
      dirs.each do |dir|
        next if dir =~ %r/^output(\/.*)?$/
        files[dir].sort.each {|file| cp file}
      end
    end
  end

  # Make a directory in the user specified site location. A message will be
  # displayed to the screen indicating tha the directory is being created.
  #
  def mkdir( dir )
    dir = dir.empty? ? site : site / dir
    if test ?d, dir
      exists dir
    else
      create dir
      FileUtils.mkdir_p dir unless pretend?
    end
  end

  # Copy a file from the template location to the user specified site
  # location. A message will be displayed to the screen indicating tha the
  # file is being created.
  #
  def cp( file )
    src = template / file
    dst = site / file

    if test(?e, dst) 
      if identical?(src, dst)
        identical(dst)
        return
      end

      choice = case options[:collision]
        when :force then :force
        when :skip  then :skip
        else force_file_collision?( dst ) end

      case choice
        when :force then force(dst)
        when :skip  then skip(dst); return
        else raise "Invalid collision choice: #{choice.inspect}" end
    else
      create(dst)
    end
    return if pretend?

    if WINDOWS then win_line_endings(src, dst)
    else FileUtils.cp(src, dst) end
  end

  # Copy the file from the _src_ location to the _dst_ location and
  # transform the line endings to the windows "\r\n" format.
  #
  def win_line_endings( src, dst )
    case ::File.extname(src)
    when *%w[.png .gif .jpg .jpeg]
      FileUtils.cp src, dst
    else
      ::File.open(dst,'w') do |fd|
        ::File.foreach(src, "\n") do |line|
          line.tr!("\r\n",'')
          fd.puts line
        end
      end
    end
  end

  %w[exists create force skip identical].each do |m|
    class_eval "def #{m}( msg ) message('#{m}', msg); end"
  end

  # Print the given message and message type to stdout.
  #
  def message( type, msg )
    msg = msg.sub(%r/#{site}\/?/, '')
    return if msg.empty?
    @stdout.puts "%13s  %s" % [type, msg]
  end

  # Prints an abort message to the screen and then exits the Ruby
  # interpreter. A non-zero return code is used to indicate an error.
  #
  def abort( msg )
    @stdout.puts "\nAborting!"
    @stdout.puts "    #{msg}"
    @stdout.puts
    exit 1
  end

  # Iterates over all the files in the template directory and stores them in
  # a hash.
  #
  def site_files
    exclude = %r/tmp$|bak$|~$|CVS|\.svn/o

    rgxp = %r/\A#{template}\/?/o
    paths = Hash.new {|h,k| h[k] = []}

    Find.find(template) do |p|
      next if exclude =~ p

      if test(?d, p)
        paths[p.sub(rgxp, '')]
        next
      end
      dir = ::File.dirname(p).sub(rgxp, '')
      paths[dir] << p.sub(rgxp, '')
    end

    paths
  end

  # Returns +true+ if the source file is identical to the destination file.
  # Returns +false+ if this is not the case.
  #
  def identical?( src, dst )
    # FIXME: this most likely won't work on windows machines
    #        because the line endings are modified when the site is gnerated
    source      = IO.read(src)
    destination = IO.read(dst)
    source == destination
  end

  # Ask the user what to do about the file collision.
  #
  def force_file_collision?( dst )
    dst = dst.sub(%r/#{site}\/?/, '')
    @stdout.print "overwrite #{dst}? [(Y)es (n)o (q)uit] "
    @stdout.flush
    case @stdin.gets
      when %r/q/i  then abort 'user asked to quit'
      when %r/n/i  then :skip
      when %r/y/i  then :force
      when %r/\s*/ then :force
      else force_file_collision?(dst) end
  rescue
    retry
  end

end  # class Generator
end  # class Webby::Main

# EOF
