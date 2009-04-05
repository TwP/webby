require 'fileutils'
require 'optparse'
require 'forwardable'

module Webby::Apps

# webby gen template site  => creates the tmplate
# webby gen -h / --help
# webby gen       => same as --help
#

class Generator
  extend Forwardable

  # Create a new Generator instance and run the +webby+ application given the
  # command line _args_.
  #
  def self.run( args )
    self.new.run args
  end

  attr_accessor :template, :site
  attr_reader :options

  # Initialize a new generator object.
  #
  def initialize( output = $stdout, input = $stdin )
    @options = {}
    @site = @template = nil
    @output, @input = output, input
    @journal = journal
  end

  def_delegators :@journal,
                 :exists, :create, :force, :skip, :identical

  # Writes the given objects to the output destination. Each object is
  # followed by a newline unless the object is a string with a newline
  # already at the end.
  #
  def puts( *args )
    @output.puts(*args)
  end

  # Writes the given objects to the output destination.
  #
  def print( *args )
    @output.print(*args)
  end

  # Reads a line text frim the input source.
  #
  def gets
    @input.gets
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
    opts.banner = 'Usage: webby-gen [options] template site'

    opts.separator ''
    opts.separator 'The webby-gen command is used to generate a site from a standard template.'
    opts.separator 'A new site can be created, or an existing site can be added to or updated.'

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
      ary = templates.map {|t| ::File.basename(t)}
      ary.delete 'webby'
      puts "\nAvailable Templates"
      puts "    #{ary.join(', ')}"
      puts
      exit
    }

    opts.separator ''
    opts.separator 'common options:'

    opts.on( '-h', '--help', 'show this message' ) {puts opts; exit}
    opts.on( '--version', 'show version' ) do
      puts "Webby #{::Webby::VERSION}"
      exit
    end

    # parse the command line arguments
    opts.parse! args
    tmpl, @site = args

    # if no site was given, see if there is a Sitefile in the current
    # directory
    if site.nil?
      self.site = '.' if test(?f, 'Sitefile')
    end

    # exit if comand line args are missing
    if site.nil? or tmpl.nil?
      puts opts
      exit 1
    end

    templates.each {|t| self.template = t if t =~ %r/\/#{tmpl}$/}
    if template.nil?
      puts opts
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

    FileUtils.cp(src, dst)
  end

  # Prints an abort message to the screen and then exits the Ruby
  # interpreter. A non-zero return code is used to indicate an error.
  #
  def abort( msg )
    puts "\nAborting!"
    puts "    #{msg}"
    puts
    exit 1
  end

  # Iterates over all the files in the template directory and stores them in
  # a hash.
  #
  def site_files
    exclude = %r/tmp$|bak$|~$|CVS|\.svn/o

    rgxp = %r/\A#{template}\/?/
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
    source      = IO.read(src)
    destination = IO.read(dst)
    source == destination
  end

  # Ask the user what to do about the file collision.
  #
  def force_file_collision?( dst )
    dst = dst.sub(%r/#{site}\/?/, '')
    print "overwrite #{dst}? [(Y)es (n)o (q)uit] "
    case gets
      when %r/q/i  then abort 'user asked to quit'
      when %r/n/i  then :skip
      when %r/y/i  then :force
      when %r/\s*/ then :force
      else force_file_collision?(dst) end
  rescue
    retry
  end

end  # class Generator
end  # module Webby::Apps

# EOF
