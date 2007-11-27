# $Id$

module Webby

# A Webby::Resource is any file that can be found in the content directory
# or in the layout directory. This class contains information about the
# resources available to Webby. This information includes the resource
# type (static, page, layout), if the resource is dirty (it needs to be
# rendered), the output location of the rendered resource, etc.
#
# A resource is a "layout" if the resource is found in the layout
# directory. Static and page resources are found in the content directory.
#
# A resource is considered static only if it *does not* contain a YAML
# meta-data header at the top of the file. These resources will be copied
# as-is from the content directory to the output directory.
#
# If a resouce does have meta-data, then it will be processed (i.e.
# rendered/filtered) by Webby, and the rendered results will be written to
# the output directory.
#
class Resource

  class << self
    # Returns the pages hash object.
    def pages
      @pages ||= PagesDB.new
    end

    # Returns the layouts hash object.
    def layouts
      @layouts ||= PagesDB.new
    end

    # Clear the contents of the +layouts+ and the +pages+ hash objects.
    def clear
      self.pages.clear
      self.layouts.clear
    end
  end  # class << self

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

  # Resource page number (if needed)
  attr_reader :number

  # call-seq:
  #    Resource.new( filename )    => resource
  #
  # Creates a new resource object given the _filename_.
  #
  def initialize( fn )
    @path     = fn.sub(%r/\A(?:\.\/|\/)/o, '').freeze
    @dir      = ::File.dirname(@path).sub(%r/\A[^\/]+\/?/o, '')
    @filename = ::File.basename(@path).sub(%r/\.\w+\z/o, '')
    @ext      = ::File.extname(@path).sub(%r/\A\.?/o, '')
    @mtime    = ::File.mtime @path

    @number = nil
    @rendering = false

    # deal with the meta-data
    @mdata = ::Webby::File.meta_data(@path)
    @have_mdata = !@mdata.nil?

    @mdata ||= {}
    @mdata = ::Webby.page_defaults.merge(@mdata) if is_page?
    @mdata.sanitize!

    self.class.pages << self if is_page? or is_static?
    self.class.layouts << self if is_layout?
  end

  # call-seq:
  #    equal?( other )    => true or false
  #
  # Returns +true+ if the path of this resource is equivalent to the path of
  # the _other_ resource. Returns +false+ if this is not the case.
  #
  def equal?( other )
    return false unless self.class == other.class
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
    return unless self.class == other.class
    @path <=> other.path
  end

  # call-seq:
  #    extension    => string
  #
  # Returns the extension that will be appended to the output destination
  # filename. The extension is determined by looking at the following:
  #
  # * this resource's meta-data for an 'extension' property
  # * the meta-data of this resource's layout for an 'extension' propery
  # * the extension of this resource file
  #
  def extension
    return @mdata['extension'] if @mdata.has_key? 'extension'

    if @mdata.has_key? 'layout'
      lyt = self.class.layouts.find :filename => @mdata['layout']
      break if lyt.nil?
      return lyt.extension
    end

    @ext
  end

  # call-seq:
  #    destination    => string
  #
  # Returns the path in the output directory where the results of rendering
  # this resource should be stored. This path is used to determine if the
  # resource is dirty and in need of rendering.
  #
  # The destination for any resource can be overridden by explicitly setting
  # the 'destination' propery in the resource's meta-data.
  #
  def destination
    return @dest if defined? @dest and @dest
    return @dest = ::Webby.cairn if is_layout?

    @dest = if @mdata.has_key? 'destination' then @mdata['destination']
            else File.join(dir, filename) end

    @dest = File.join(::Webby.config['output_dir'], @dest)
    @dest << @number.to_s if @number
    @dest << '.'
    @dest << extension
    @dest
  end

  # call-seq
  #    href    => string or nil
  #
  # Returns a string suitable for use as an href linking to this page. Nil
  # is returned for layouts.
  #
  def href
    return nil if is_layout?
    return @href if defined? @href and @href

    @href = destination.sub(::Webby.config['output_dir'], '')
    @href
  end

  # call-seq:
  #    resource.number = Integer
  #
  # Sets the page number for the current resource to the given integer. This
  # number is used to modify the output destination for resources that
  # require pagination.
  #
  def number=( num )
    @number = num
    @dest = nil
  end

  # call-seq:
  #    render   => string
  #
  # Creates a new Webby::Renderer instance and uses that instance to render
  # the resource contents using the configured filter(s). The filter(s) to
  # use is defined in the resource's meta-data as the 'filter' key.
  #
  # Note, this only renders this resource. The returned string does not
  # include any layout rendering.
  #
  def render( renderer = nil )
    raise Error, "page '#@path' is in a rendering loop" if @rendering

    @rendering = true
    renderer ||= Renderer.new(self)
    content = renderer.render_page
    @rendering = false

    return content

  rescue
    @rendering = false
    raise
  end

  # call-seq:
  #    is_layout?    => true or false
  #
  # Returns +true+ if this resource is a layout.
  #
  def is_layout?
    @is_layout ||=
        !(%r/\A(?:\.\/|\/)?#{::Webby.config['layout_dir']}\//o =~ @path).nil?
  end

  # call-seq:
  #    is_static?    => true or false
  #
  # Returns +true+ if this resource is a static file.
  #
  def is_static?
    !@have_mdata
  end

  # call-seq:
  #    is_page?    => true or false
  #
  # Returns +true+ if this resource is a page suitable for rendering.
  #
  def is_page?
    @have_mdata and !is_layout?
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
    return true unless test ?e, destination

    # if this file's mtime is larger than the destination file's
    # mtime, then we are dirty
    dirty = @mtime > File.mtime(destination)
    return dirty if is_static? or dirty

    # check to see if the layout is dirty, and it it is then we
    # are dirty, too
    if @mdata.has_key? 'layout'
      lyt = self.class.layouts.find :filename => @mdata['layout']
      unless lyt.nil?
        return true if lyt.dirty?
      end
    end

    # if we got here, then we are not dirty
    false
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

end  # class Resource
end  # module Webby

# EOF
