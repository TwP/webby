require Webby.libpath(*%w[webby resources resource])

module Webby::Resources

# A Page is a file in the content folder that contains YAML meta-data at
# the top of the file. Pages are processed by the Webby rendering engine
# and then inserted into the desired layout. The string resulting from
# processing and layout is then written to the output directory.
#
class Page < Resource

  # call-seq:
  #    Resource.new( path )
  #
  # Creates a new page object from the full path to the page file.
  #
  def initialize( fn, meta_data = nil )
    super(fn)

    if meta_data.instance_of?(Hash)
      @_meta_data = meta_data
    else
      @_meta_data = MetaFile.meta_data(@path)
      @_meta_data ||= {}
    end
    @_meta_data = ::Webby.site.page_defaults.merge(@_meta_data)
    @_meta_data.sanitize!
  end

  # call-seq:
  #    render   => string
  #
  # This method is being deprecated. Please use the +Renderer#render+ method
  # instead.
  #
  def render( renderer = nil )
    Webby.deprecated "render", "it is being replaced by the Renderer#render() method"
    renderer ||= ::Webby::Renderer.new(self)
    renderer._render_page
  end

  # call-seq
  #    url    => string or nil
  #
  # Returns a string suitable for use as a URL linking to this page. Nil
  # is returned for layouts.
  #
  def url
    return @url unless @url.nil?

    @url = super
    if filename == 'index'
      @url = File.dirname(@url)
      @url << '/' unless %r/\/$/ =~ @url
    end
    @url
  end

  # call-seq:
  #    extension    => string
  #
  # Returns the extension that will be appended to the output destination
  # filename. The extension is determined by looking at the following:
  #
  # * this page's meta-data for an 'extension' property
  # * the meta-data of this page's layout for an 'extension' property
  # * the extension of this page file
  #
  def extension
    return _meta_data['extension'] if _meta_data.has_key? 'extension'

    if _meta_data.has_key? 'layout'
      lyt = ::Webby::Resources.find_layout(_meta_data['layout'])
      lyt_ext = lyt ? lyt.extension : nil
      return lyt_ext if lyt_ext
    end

    ext
  end

end  # class Page
end  # module Webby::Resources

# EOF
