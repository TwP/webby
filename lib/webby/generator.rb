require 'filutils'
require 'optparse'

module Webby

# webby gen template dest  => creates the tmplate
# webby gen templates      => lists available templates
# webby gen -h / --help
# webby gen       => same as --help
#

class Generator

  WINDOWS = %r/djgpp|(cyg|ms|bcc)win|mingw/ =~ RUBY_PLATFORM    # :nodoc:

  attr_accessor :template, :site

  def initialize
    @force = @update = @pretend = false
    @site = @template = nil
  end

  %w[update force pretend].each do |m|
    class_eval "def #{m}?() @#{m}; end"
  end

  def run( args )
    parse args
    create_site
  end

  def parse( args )
    opts = OptionParser.new
    opts.banner << ' gen [template] [site]'

    opts.separator ''
    opts.on('-f', '--force',
            'overwrite files that already exist') {@force = true}
    opts.on('-s', '--skip',
            'skip files that already exist') {@force = true}
    opts.on('-u', '--update',
            'update rake tasks for the site') {@update = true}
    opts.on('-p', '--pretend',
            'run but do not make any changes') {@pretend = true}

    opts.separator ''
    opts.on('-t', '--templates', 'list available templates') {
      puts opts
      ary = templates.map {|t| ::File.basename(t)}
      ary.delete! 'webby'
      puts "\nAvailable Templates"
      puts "    #{ary.join(', ')}\n"
      exit
    }

    opts.separator ''
    opts.separator 'common options:'

    opts.on_tail( '-h', '--help', 'show this message' ) {puts opts; exit}
    opts.on_tail( '--version', 'show version' ) do
      puts "Webby #{::Webby::VERSION}"
      exit
    end

    # parse the command line arguments
    opts.parse! args
    tmpl, @site = args

    if @site.nil? or tmpl.nil?
      puts opts
      exit 1
    end

    templates.each {|t| self.template = t if t =~ %r/\/#{tmpl}$/}
    if @template.nil?
      puts opts
      abort "Could not find template '#{tmpl}'"
    end

    nil
  end

  # Returns an array of available site templates.
  #
  def templates
    Dir.glob(::Webby.path('examples') / '*').sort
  end

  #
  #
  def create_site
    unless test ?e, site
      FileUtils.mkdir_p site unless pretend?
    end

    files = site_files

    if update?
      mkdir 'tasks'
      files['tasks'].sort.each {|file| cp file}
    else
      dirs = files.keys.sort

      dirs.each {|dir| mkdir dir}
      dirs.each do |dir|
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
      # TODO: test for identical files
      if    force? then force(dst)
      elsif skip?  then skip(dst); return
      else
      # TODO: query the user for what to do with this file
        skip(dst)
        return
      end
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
    class_eval "def #{m}( msg ) message(#{m}, msg); end"
  end

  def message( type, msg )
    msg = msg.sub(%r/#{site}\/?/, '')
    puts "%13s  %s" % [type, msg]
  end

  # Prints an abort message to the screen and then exits the Ruby
  # interpreter. A non-zero return code is used to indicate an error.
  #
  def abort( msg )
    puts "\n    #{msg}\n"
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

end  # class Generator
end  # module Webby

# EOF
