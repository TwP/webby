unless defined? Webby::Resources::Resource

module Webby::Resources

# A Webby::Resource is any file that can be found in the content directory
# or in the layout directory. This class contains information about the
# resources available to Webby.
#
class Resource

  instance_methods.each do |m|
      undef_method(m) unless m =~ %r/\A__|\?$/ ||
                             m == 'class'
  end

  # The full path to the resource file
  attr_reader :path

  # The directory of the resource excluding the content directory
  attr_reader :dir

  # The resource filename excluding path and extension
  attr_reader :filename

  # Extesion of the resource file
  attr_reader :ext

  # Resource file modification time
  attr_reader :mtime

  # call-seq:
  #    Resource.new( filename )    => resource
  #
  # Creates a new resource object given the _filename_.
  #
  def initialize( fn )
    @path     = fn
    @dir      = ::Webby::Resources::File.dirname(@path)
    @filename = ::Webby::Resources::File.basename(@path)
    @ext      = ::Webby::Resources::File.extname(@path)
    @mtime    = ::File.mtime @path

    @mdata = @@mdata ||= {}
  end

  # call-seq:
  #    equal?( other )    => true or false
  #
  # Returns +true+ if the path of this resource is equivalent to the path of
  # the _other_ resource. Returns +false+ if this is not the case.
  #
  def equal?( other )
    return false unless other.kind_of? ::Webby::Resources::Resource
    @path == other.path
  end
  alias :== :equal?
  alias :eql? :equal?

  # call-seq:
  #    resource <=> other    => -1, 0, +1, or nil
  #
  # Resource comparison operates on the full path of the resource objects
  # and uses the standard String comparison operator. Returns +nil+ if
  # _other_ is not a Resource instance.
  #
  def <=>( other )
    return unless other.kind_of? ::Webby::Resources::Resource
    @path <=> other.path
  end

  # call-seq:
  #    resource[key]    => value or nil
  #
  # Returns the value associated with the given meta-data key. Key is
  # converted into a string.
  #
  def []( key )
    @mdata[key.to_s]
  end

  # call-seq:
  #    resource[key] = value
  #
  # Sets the given meta-data key to the value. Key is converted into a
  # string.
  #
  def []=( key, value )
    @mdata[key.to_s] = value
  end

  # call-seq:
  #    method_missing( symbol [, *args, &block] )    => result
  #
  # Invoked by Ruby when a message is sent to the resource that it cannot
  # handle. The default behavior is to convert _symbol_ to a string and
  # search for that string in the resource's meta-data. If found, the
  # meta-data item is returned; otherwise, +nil+ is returned.
  #
  def method_missing( name, *a, &b )
    @mdata[name.to_s]
  end

  # call-seq:
  #    dirty?    => true or false
  #
  # Returns +true+ if this resource is newer than its corresponding output
  # product. The resource needs to be rendered (if a page or layout) or
  # copied (if a static file) to the output directory.
  #
  def dirty?
    return @mdata['dirty'] if @mdata.has_key? 'dirty'

    # if the destination file does not exist, then we are dirty
    return true unless test(?e, destination)

    # if this file's mtime is larger than the destination file's
    # mtime, then we are dirty
    dirty = @mtime > ::File.mtime(destination)
    return dirty if dirty

    # check to see if the layout is dirty, and if it is then we
    # are dirty, too
    if @mdata.has_key? 'layout'
      lyt = ::Webby::Resources.layouts.find :filename => @mdata['layout']
      unless lyt.nil?
        return true if lyt.dirty?
      end
    end

    # if we got here, then we are not dirty
    false
  end

  # call-seq
  #    url    => string or nil
  #
  # Returns a string suitable for use as a URL linking to this page. Nil
  # is returned for layouts.
  #
  def url
    return @url if defined? @url and @url
    @url = destination.sub(::Webby.site.output_dir, '')
  end

  # :stopdoc:
  def destination
    raise NotImplementedError
  end

  def extension
    raise NotImplementedError
  end
  # :startdoc:

end  # class Resource
end  # module Webby::Resources

end  # unless defined?

# EOF
