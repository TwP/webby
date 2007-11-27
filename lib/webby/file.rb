# $Id$

require 'yaml'

module Webby

# The Webby::File class is identical to the core Ruby file class except for
# YAML meta-data stored at the top of the file. This meta-data is made
# available through the <code>meta_data</code> and <code>meta_data=</code>
# functions.
#
# The meta-data data must be found between two YAML block separators "---",
# each on their own line.
#
# Example:
#
#     ---
#     layout: blog
#     filter: markdown
#     tags:
#       - ruby
#       - web development
#     ---
#     This is a blog entry formatted using MarkDown and tagged as "ruby" and
#     "web development". The layout being used is the "blog" format.
#
class File < ::File

  META_SEP = %r/\A---\s*\r?\n\z/o   # :nodoc:

  class << self
    # call-seq:
    #    Webby::File.read( name [, length [, offset]])    => string
    #
    # Opens the file, optionally seeks to the given _offset_, then returns
    # _length_ bytes (defaulting to the rest of the file). +read+ ensures
    # the file is closed before returning.
    #
    def read( name, *args )
      fd = new name, 'r'
      fd.read *args
    ensure
      fd.close unless fd.nil?
    end

    # call-seq:
    #    Webby::File.readlines( name, sep_string = $/ )    => array
    #
    # Reads the entire file specified by _name_ as individual lines, and
    # returns those lines in an array. Lines are separated by _sep_string_.
    # +readlines+ ensures the file is closed before returning.
    #
    def readlines( name, sep = $/ )
      fd = new name, 'r'
      fd.readlines sep
    ensure
      fd.close unless fd.nil?
    end

    # call-seq:
    #    Webby::File.meta_data( name )    => object or nil
    #
    # Reads the meta-data from the file specified by _name_. +meta_data+
    # ensures the files is closed before returning.
    #
    def meta_data( name )
      fd = new name, 'r'
      fd.meta_data
    ensure
      fd.close unless fd.nil?
    end
  end

  # call-seq:
  #    Webby::File.new( filename, mode = "r" )          => file
  #    Webby::File.new( filename [, mode [, perm]] )    => file
  #
  # Opens the file named by _filename_ according to _mode_ (default is 'r')
  # and returns a new +Webby::File+ object. See the description of class
  # +IO+ for a description of _mode_. The file _mode_ may optionally be
  # specified as a +Fixnum+ by or-ing together the flags (+O_RDONLY+ etc,
  # again described under +IO+). Optional permission bits may be given in
  # _perm_. These _mode_ and permission bits are platform dependent; on Unix
  # systems, see +open(2)+ for details. 
  #
  #    f = File.new("testfile", "r")
  #    f = File.new("newfile",  "w+")
  #    f = File.new("newfile", File::CREAT|File::TRUNC|File::RDWR, 0644)
  #
  def initialize( *args )
    super
    @meta_end = end_of_meta_data
  end

  # call-seq:
  #    meta_data
  #
  # Returns the meta-data defined at the top of the file. Returns +nil+ if
  # no meta-data is defined. The meta-data is returned as Ruby objects
  #
  # Meta-data is stored in YAML format between two YAML separators "---" on
  # their own lines.
  #
  def meta_data
    return if @meta_end.nil?

    cur, meta_end, @meta_end = tell, @meta_end, nil
    seek 0
    return YAML.load(self)

  ensure
    @meta_end = meta_end if defined? meta_end and meta_end
    seek cur if defined? cur and cur
  end

  # call-seq
  #    meta_data = object
  #
  # Stores the given _object_ as meta-data in YAML format at the top of the
  # file. If the _objectc_ is +nil+, then the meta-data section will be
  # removed from the file.
  #
  # Meta-data is stored in YAML format between two YAML separators "---" on
  # their own lines.
  #
  def meta_data=( data )
    return if data.nil? and @meta_end.nil?

    seek 0
    lines = readlines

    truncate 0
    unless data.nil?
      write YAML.dump(data)
      write "--- #$/"
    end
    lines.each {|line| write line}
  ensure
    @meta_end = end_of_meta_data
    seek 0, IO::SEEK_END
  end

  %w(getc gets read read_nonblock readbytes readchar readline readlines readpartial scanf).each do |m|
    self.class_eval <<-CODE
      def #{m}(*a)
        skip_meta_data
        super
      end
    CODE
  end


  private

  # Moves the file pointer to the end of the meta-data section. Does nothing
  # if there is no meta-data section or if the file pointer is already past
  # the meta-data section.
  #
  def skip_meta_data
    return if @meta_end.nil? 
    return if tell >= @meta_end
    seek @meta_end
  end

  # Returns the position in this file where the meta-data ends and the file
  # data begins. If there is no meta-data in the file, returns +nil+.
  #
  def end_of_meta_data
    cur = tell

    seek 0
    line = gets
    return unless META_SEP =~ line

    while line = gets
      break if META_SEP =~ line
    end
    return if line.nil?
    tell

  ensure
    seek cur
  end

end  # class File
end  # module Webby

# EOF
