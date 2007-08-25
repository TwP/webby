# $Id$

module Webby

#
#
class Resource

  class << self
    def pages
      @pages ||= PagesDB.new
    end

    def layouts
      @layouts ||= PagesDB.new
    end

    def clear
      self.pages.clear
      self.layouts.clear
    end
  end  # class << self

  # call-seq:
  #    Resource.new( filename )    => resource
  #
  def initialize( fn )
    @path     = fn.sub(%r/\A(?:\.\/|\/)/o, '').freeze
    @dir      = ::File.dirname(@path).sub(%r/\A[^\/]+\/?/o, '')
    @filename = ::File.basename(@path).sub(%r/\.\w+\z/o, '')
    @ext      = ::File.extname(@path).sub(%r/\A\.?/o, '')
    @mtime    = ::File.mtime @path

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
  def equal?( other )
    return false unless self.class == other.class
    @path == other.path
  end
  alias :== :equal?
  alias :eql? :equal?

  # call-seq:
  #    resource <=> other    => -1, 0, +1, or nil
  #
  def <=>( other )
    return unless self.class == other.class
    @path <=> other.path
  end


  attr_reader :path, :dir, :filename, :mtime, :ext

  # call-seq:
  #    extension    => string
  #
  def extension
    return @mdata['extension'] if @mdata.has_key? 'extension'

    if @mdata.has_key? 'layout'
      lyt = self.class.layouts.find_by_name @mdata['layout']
      break if lyt.nil?
      return lyt.extension
    end

    @ext
  end

  def destination
    return @destination if defined? @destination
    return @destination = ::Webby.config['output_dir'] if is_layout?

    @destination = File.join(::Webby.config['output_dir'], dir, filename)
    @destination << '.'
    @destination << extension
    @destination
  end

  # call-seq:
  #    render   => string
  #
  def render
    raise Error, "page '#@path' is in a rendering loop" if @rendering

    @rendering = true
    content = Renderer.new(self).render_page
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
    return @mdata['dirty'] = true unless test ?e, destination

    # if this file's mtime is larger than the destination file's
    # mtime, then we are dirty
    @mdata['dirty'] = @mtime > File.mtime(destination)
    return @mdata['dirty'] if is_static? or @mdata['dirty']

    # check to see if the layout is dirty, and it it is then we
    # are dirty, too
    if @mdata.has_key? 'layout'
      lyt = self.class.layouts.find_by_name @mdata['layout']
      break if lyt.nil?
      return @mdata['dirty'] = true if lyt.dirty?
    end

    # if we got here, then we are not dirty
    @mdata['dirty'] = false
  end

  def method_missing( name, *a, &b )
    @mdata[name.to_s]
  end

end  # class Resource
end  # module Webby

# EOF
