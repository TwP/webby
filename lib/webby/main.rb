# $Id$

require 'fileutils'
require 'find'

module Webby

# The Webby::Main class contains all the functionality needed by the +webby+
# command line application.
#
class Main

  # Directory where the Webby website will be created
  attr_accessor :site

  # Directory where the prototype Webby website can be found
  attr_accessor :data

  # call-seq:
  #    Main.run( *args )    => nil
  #
  # Create a new instance of Main, and run the +webby+ application given the
  # command line _args_.
  #
  def self.run( *args )
    self.new.run *args
  end

  # call-seq:
  #    run( *args )    => nil
  #
  # Run the +webby+ application given the command line _args_.
  #
  def run( *args )
    abort "Usage: #{$0} /path/to/your/site" unless args.length == 1

    self.site = args.at 0
    self.data = File.join(::Webby::PATH, 'data')

    # see if the site already exists
    abort "#{site} already exists" if test ?e, site

    # copy over files from the data directory
    files = site_files

    files.keys.sort.each do |dir|
      mkdir dir
      files[dir].each {|file| cp file}
    end
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
    creating dir
    FileUtils.mkdir_p dir
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
    creating dst
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
