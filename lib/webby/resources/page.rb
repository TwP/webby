require Webby.libpath(*%w[webby resources resource])

module Webby::Resources

# A Page is a file in the content folder that contains YAML meta-data at
# the top of the file. Pages are processed by the Webby rendering engine
# and then inserted into the desired layout. The string resulting from
# processing and layout is then written to the output directory.
#
class Page < Resource

  # Resource page number (if needed)
  attr_reader :number

  # call-seq:
  #    Resource.new( path )
  #
  # Creates a new page object from the full path to the page file.
  #
  def initialize( fn )
    super
    @number = nil

    @mdata = ::Webby::Resources::File.meta_data(@path)
    @mdata ||= {}
    @mdata = ::Webby.site.page_defaults.merge(@mdata)
    @mdata.sanitize!
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
    return @url if defined? @url and @url

    @url = destination.sub(::Webby.site.output_dir, '')
    @url = File.dirname(@url) if filename == 'index' and number.nil?
    @url
  end

  # call-seq:
  #    page.number = Integer
  #
  # Sets the page number for the current resource to the given integer. This
  # number is used to modify the output destination for resources that
  # require pagination.
  #
  def number=( num )
    @number = num
    @url = @dest = nil
  end

  # call-seq:
  #    destination    => string
  #
  # Returns the path in the output directory where the rendered page should
  # be stored. This path is used to determine if the page is dirty and in
  # need of rendering.
  #
  # The destination for a page can be overridden by explicitly setting
  # the 'destination' property in the page's meta-data.
  #
  def destination
    return @dest if defined? @dest and @dest

    @dest = if @mdata.has_key? 'destination' then @mdata['destination']
            else ::File.join(dir, filename) end

    @dest = ::File.join(::Webby.site.output_dir, @dest)
    @dest << @number.to_s if @number

    ext = extension
    unless ext.nil? or ext.empty?
      @dest << '.' << ext
    end
    @dest
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
    return @mdata['extension'] if @mdata.has_key? 'extension'

    if @mdata.has_key? 'layout'
      lyt = ::Webby::Resources.layouts.find :filename => @mdata['layout']
      ext = lyt ? lyt.extension : nil
      return ext if ext
    end
    @ext
  end

end  # class Page
end  # module Webby::Resources

# EOF
