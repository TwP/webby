require 'yaml'

module Webby::Resources

# The MetaFile class is used to read meta-data and content from files. The
# meta-data is in a YAML block located at the top of the file. The content
# is the remainder of the file (everything after the YAML block).
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

  class Error < StandardError; end

  META_SEP = %r/\A---\s*(?:\r\n|\n)?\z/   # :nodoc:
  ERR_MSG = "corrupt meta-data (perhaps there is an errant YAML marker '---' in the file)" # :nodoc:

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

  # call-seq:
  #    MetaFile.meta_data?( filename )    => true or false
  #
  # Opens the file identified by _filename_ and returns true if there is a
  # meta-data block at the top of the file, and returns false if there is
  # not a meta-data block at the top of the file.
  #
  def self.meta_data?( name )
    ::File.open(name, 'r') {|fd| MetaFile.new(fd).meta_data?}
  end

  # Creates a new MetaFile parser that will read from the given _io_ stream.
  #
  def initialize( io )
    raise ArgumentError, "expecting an IO stream" unless io.respond_to? :gets
    @io = io
    @meta_count = 0
  end

  # Returns the entire contents of the IO stream exluding any meta-data
  # found at the beginning of the stream.
  #
  def read
    count = meta_end
    @io.seek 0
    count.times {@io.gets} unless count.nil?
    @io.read
  end

  # Reads in each meta-data section and yields it to the given block. The
  # first meta-data section is yielded "as is", but subsequent meta-data
  # sections are merged with this first section and then yielded. This
  # allows the user to define common items in the first meta-data section
  # and only include items that are different in the subsequent sections.
  #
  # Example:
  #
  #    ---
  #    title:      First Title
  #    author:     me
  #    directory:  foo/bar/baz
  #    ---
  #    title:      Second Title
  #    author:     you
  #    ---
  #    title:      Third Title
  #    author:     them
  #    ---
  #
  # and parsing the meta-data above yields ...
  #
  #    meta_file.each do |hash|
  #      pp hash
  #    end
  #
  # the following output
  #
  #    { 'title' => 'First Title',
  #      'author' => 'me',
  #      'directory' => 'foo/bar/baz' }
  #
  #    { 'title' => 'Second Title',
  #      'author' => 'you',
  #      'directory' => 'foo/bar/baz' }
  #
  #    { 'title' => 'Third Title',
  #      'author' => 'them',
  #      'directory' => 'foo/bar/baz' }
  #
  # Even though the "directory" item only appears in the first meta-data
  # block, it is copied to all the subsequent blocks.
  #
  def each
    return unless meta_data?

    first, count = nil, 0
    @io.seek 0

    buffer = @io.gets
    while count < @meta_count
      while (line = @io.gets) !~ META_SEP
        buffer << line
      end

      begin
        h = YAML.load(buffer)
      rescue Psych::SyntaxError => err
        msg = ERR_MSG.dup << "\n\t-- " << err.message
        msg << "\n Buffer:\n#{buffer}"
        raise Error, msg
      end

      raise Error, ERR_MSG unless h.instance_of?(Hash)

      if first then h = first.merge(h)
      else first = h.dup end

      buffer = line
      count += 1

      yield h
    end
  rescue ArgumentError => err
    msg = ERR_MSG.dup << "\n\t-- " << err.message
    raise Error, msg
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

  # Returns true if the IO stream contains meta-data. Returns false if the
  # IO stream does not contain meta-data.
  #
  def meta_data?
    meta_end.nil? ? false : true
  end

  # Returns the number of meta-data blocks at the top of the file.
  #
  def meta_count
    meta_end
    @meta_count
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
    @io.gets
    pos, count = nil, 1

    while line = @io.gets
      count += 1
      if META_SEP =~ line
        pos = count
        @meta_count += 1
      end
    end
    return if pos.nil?

    @meta_end = pos
  end

end  # class MetaFile
end  # module Webby::Resources

# EOF
