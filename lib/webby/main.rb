# $Id$

require 'fileutils'
require 'find'
require 'optparse'

module Webby

# The Webby::Main class contains all the functionality needed by the +webby+
# command line application.
#
class Main

  # Directory where the Webby website will be created
  attr_accessor :site

  # Directory where the prototype Webby website can be found
  attr_accessor :data

  # Flag used to update an existing website
  attr_accessor :update

  # call-seq:
  #    Main.run( args )    => nil
  #
  # Create a new instance of Main, and run the +webby+ application given the
  # command line _args_.
  #
  def self.run( args )
    m = self.new
    m.parse args

    if m.update then m.update_site
                else m.create_site end
  end

  # call-seq:
  #    parse( args )   => nil
  #
  # Parse the command line arguments and store the values for later use by
  # the create_site and update_site methods.
  #
  def parse( args )
    self.data = File.join(::Webby::PATH, 'data')
    self.update = false

    opts = OptionParser.new
    opts.banner << ' site'

    opts.separator ''
    opts.on('-u', '--update',
            'update the rake tasks for the site') {self.update = true}

    opts.separator ''
    opts.separator 'common options:'

    opts.on_tail( '-h', '--help', 'show this message' ) {puts opts; exit}
    opts.on_tail( '--version', 'show version' ) do
      puts "Webby #{::Webby::VERSION}"
      exit
    end

    # parse the command line arguments
    opts.parse! args
    self.site = args.shift

    if site.nil?
      puts opts
      ::Kernel.abort
    end
    nil
  end

  # call-seq:
  #    create_site    => nil
  #
  # Create a new website.
  #
  def create_site
    # see if the site already exists
    abort "'#{site}' already exists" if test ?e, site

    # copy over files from the data directory
    files = site_files

    files.keys.sort.each do |dir|
      mkdir dir
      files[dir].sort.each {|file| cp file}
    end
    nil
  end

  # call-seq:
  #    update_site    => nil
  #
  # Update the rake tasks for an existing website.
  #
  def update_site
    # ensure the site already exists
    abort "'#{site}' does not exist" unless test ?d, site

    # copy over files from the data/tasks directory
    files = site_files

    mkdir 'tasks'
    files['tasks'].sort.each {|file| cp file}

    nil
  end

  # call-seq:
  #    mkdir( dir )    => nil
  #
  # Make a directory in the user specified site location. A message will be
  # displayed to the screen indicating tha the directory is being created.
  #
  def mkdir( dir )
    dir = dir.empty? ? site : ::File.join(site, dir)
    unless test ?d, dir
      creating dir
      FileUtils.mkdir_p dir
    end
  end

  # call-seq:
  #    cp( file )    => nil
  #
  # Copy a file from the Webby prototype website location to the user
  # specified site location. A message will be displayed to the screen
  # indicating tha the file is being created.
  #
  def cp( file )
    src = ::File.join(data, file)
    dst = ::File.join(site, file)
    test(?e, dst) ? updating(dst) : creating(dst)
    FileUtils.cp src, dst
  end

  # call-seq:
  #    creating( msg )   => nil
  #
  # Prints a "creating _msg_" to the screen.
  #
  def creating( msg )
    print "creating "
    puts msg
  end

  # call-seq:
  #    updating( msg )   => nil
  #
  # Prints a "updating _msg_" to the screen.
  #
  def updating( msg )
    print "updating "
    puts msg
  end

  # call-seq:
  #    abort( msg )   => nil
  #
  # Prints an abort _msg_ to the screen and then exits the Ruby interpreter.
  #
  def abort( msg )
    puts msg
    puts "Aborting!"
    exit 1
  end

  # call-seq:
  #    site_files   => hash
  #
  # Iterates over all the files in the Webby prototype website directory and
  # stores them in a hash.
  #
  def site_files
    exclude = %r/tmp$|bak$|~$|CVS|\.svn/o

    rgxp = %r/\A#{data}\/?/o
    paths = Hash.new {|h,k| h[k] = []}

    Find.find(data) do |p|
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

end  # class Main
end  # module Webby

# EOF
