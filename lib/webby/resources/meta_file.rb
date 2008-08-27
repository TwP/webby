require 'yaml'

module Webby::Resources

# The Webby::Resources::File class is identical to the core Ruby file class
# except for YAML meta-data stored at the top of the file. This meta-data
# is made available through the <code>meta_data</code> and
# <code>meta_data=</code> functions.
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
class MetaFile

  META_SEP = %r/\A---\s*(?:\r\n|\n)?\z/   # :nodoc:

  # call-seq:
  #    MetaFile.read( filename )    => string
  #
  # Opens the file identified by _filename_ and returns the contents of the
  # file as a string. Any meta-data at the top of the file is skipped and
  # is not included in the returned string. If the file contains no
  # meta-data, then this method behaves the same as File#read.
  #
  def self.read( name )
    ::File.open(name, 'r') {|fd| MetaFile.new(fd).read}
  end

  # call-seq:
  #    MetaFile.meta_data( filename )    => object or nil
  #
  # Opens the file identified by _filename_ and returns the meta-data
  # located at the top of the file. If the file contains no meta-data, then
  # +nil+ is returned.
  #
  def self.meta_data( name )
    ::File.open(name, 'r') {|fd| MetaFile.new(fd).meta_data}
  end

  # Creates a new MetaFile parser that will read from the given _io_ stream.
  #
  def initialize( io )
    raise ArgumentError, "expecting an IO stream" unless io.respond_to? :gets
    @io = io
  end

  # Returns the entire contents of the IO stream exluding any meta-data
  # found at the beginning of the stream.
  #
  def read
    @io.seek(meta_end || 0)
    @io.read
  end

  # Returns the meta-data defined at the top of the file. Returns +nil+ if
  # no meta-data is defined. The meta-data is returned as Ruby objects
  #
  # Meta-data is stored in YAML format between two YAML separators "---" on
  # their own lines.
  #
  def meta_data
    return if meta_end.nil?

    @io.seek 0
    return YAML.load(@io)
  end

  # Returns the position in the IO stream where the meta-data ends and the
  # regular data begins. If there is no meta-data in the stream, returns +nil+.
  #
  def meta_end
    return @meta_end if defined? @meta_end
    @meta_end = nil

    @io.seek 0
    line = @io.read(4)
    return unless META_SEP =~ line

    @io.seek 0
    pos = @io.gets.length
    while line = @io.gets
      pos += line.length
      break if META_SEP =~ line
    end
    return if line.nil?

    @meta_end = pos
  end

end  # class MetaFile
end  # module Webby::Resources

# EOF
