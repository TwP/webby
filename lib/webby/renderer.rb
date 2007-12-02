# $Id$

require 'erb'
try_require 'bluecloth'
try_require 'redcloth'
try_require 'haml'
try_require 'sass'

module Webby

# The Webby::Renderer is used to _filter_ and _layout_ the text found in the
# resource page files in the content directory.
#
# A page is filtered based on the settings of the 'filter' option in the
# page's meta-data information. For example, if 'textile' is specified as
# a filter, then the page will be run through the RedCloth markup filter.
# More than one filter can be used on a page; they will be run in the
# order specified in the meta-data.
#
# A page is rendered into a layout specified by the 'layout' option in the
# page's meta-data information.
#
class Renderer
  include ERB::Util

  # call-seq:
  #    Renderer.write( page )
  #
  # Render the given _page_ and write the resulting output to the page's
  # destination. If the _page_ uses pagination, then multiple destination
  # files will be created -- one for each paginated data set in the page.
  #
  def self.write( page )
    renderer = self.new(page)

    loop {
      ::File.open(page.destination, 'w') do |fd|
        fd.write renderer.layout_page
      end
      break unless renderer.next_page
    }
  end

  # call-seq:
  #    Renderer.new( page )
  #
  # Create a new renderer for the given _page_. The renderer will apply the
  # desired filters to the _page_ (from the page's meta-data) and then
  # render the filtered page into the desired layout.
  #
  def initialize( page )
    unless page.is_page?
      raise ArgumentError,
            "only page resources can be rendered '#{page.path}'"
    end

    @page = page
    @pages = Resource.pages
    @content = nil

    @log = Logging::Logger[self]
  end

  # call-seq:
  #    layout_page    => string
  #
  # Apply the desired filters to the page and then render the filtered page
  # into the desired layout. The filters to apply to the page are determined
  # from the page's meta-data. The layout to use is also determined from the
  # page's meta-data.
  #
  def layout_page
    layouts = Resource.layouts
    obj = @page
    str = @page.render(self)

    loop do
      lyt = layouts.find :filename => obj.layout
      break if lyt.nil?

      @content, str = str, ::Webby::File.read(lyt.path)

      Array(lyt.filter).each do |filter|
        str = self.send(filter + '_filter', str)
      end

      @content, obj = nil, lyt
    end

    str
  end

  # call-seq:
  #    render_page    => string
  #
  # Apply the desired filters to the page. The filters to apply are
  # determined from the page's meta-data.
  #
  def render_page
    str = ::Webby::File.read(@page.path)

    Array(@page.filter).each do |filter|
      str = self.send(filter + '_filter', str)
    end

    str
  end

  # call-seq:
  #    paginate( items, per_page ) {|item| block}
  #
  # Iterate the given _block_ for each item selected from the _items_ array
  # using the given number of items _per_page_. The first time the page is
  # rendered, the items passed to the block are selected using the range
  # (0...per_page). The next rendering selects (per_page...2*per_page). This
  # continues until all _items_ have been paginated.
  #
  # Calling this method creates a <code>@pager</code> object that can be
  # accessed from the _page_. The <code>@pager</code> contains information
  # about the next page, the current page number, the previous page, and the
  # number of items in the current page.
  #
  def paginate( items, count, &block )
    @pager ||= Paginator.new(items.length, count, @page) do |offset, per_page|
      items[offset,per_page]
    end.first

    @pager.each &block
  end

  # call-seq:
  #    next_page    => true or false
  #
  # Returns +true+ if there is a next page to render. Returns +false+ if
  # there is no next page or if pagination has not been configured for the
  # current page.
  #
  def next_page
    return false unless defined? @pager and @pager

    # go to the next page; break out if there is no next page
    if @pager.next?
      @pager = @pager.next
    else
      @page.number = nil
      return false
    end

    true
  end

  # Render text via ERB using the built in ERB library.
  #
  def erb_filter( str )
    b = binding
    ERB.new(str, nil, '-').result(b)
  end

  # Render text via markdown using the BlueCloth library.
  #
  def markdown_filter( str )
    BlueCloth.new(str).to_html
  rescue NameError => err
    @log.error 'markdown filter failed (BlueCloth not installed?)'
    @log.debug err
    exit
  end

  # Render text via textile using the RedCloth library.
  #
  def textile_filter( str )
    RedCloth.new(str).to_html
  rescue NameError => err
    @log.error 'textile filter failed (RedCloth not installed?)'
    @log.debug err
    exit
  end

  # Render text via the CodeRay syntax highlighter library.
  #
  def coderay_filter( str )
    filters = nil

    if Array === @page.filter
      idx = @page.filter.index('coderay') + 1
      filters = @page.filter.slice(idx..-1)
    end

    Filters::CodeRay.new(str, filters).to_html
  rescue NameError => err
    @log.error 'coderay filter failed (CodeRay not installed?)'
    @log.debug err
    exit
  end

  # Render text into iamges via the Graphviz programs.
  #
  def graphviz_filter( str )
    filters = nil

    if Array === @page.filter
      idx = @page.filter.index('graphviz') + 1
      filters = @page.filter.slice(idx..-1)
    end

    Filters::Graphviz.new(str, filters).to_html
  rescue NameError => err
    @log.error 'graphviz filter failed (Graphviz not installed?)'
    @log.debug err
    exit
  end

  # Render text via the Haml library
  #
  def haml_filter( str )
    opts = @page.haml_options || {}
    opts[:locals] ||= {}
    opts[:locals].merge!({:page => @page, :pages => @pages})
    Haml::Engine.new(str, opts).to_html
  rescue NameError => err
    @log.error 'haml filter failed (Haml not installed?)'
    @log.debug err
    exit
  end

  # Render text via the Sass library (part of Haml)
  #
  def sass_filter( str )
    opts = @page.sass_options || {}
    Sass::Engine.new(str, opts).render
  rescue NameError => err
    @log.error 'sass filter failed (Haml not installed?)'
    @log.debug err
    exit
  end

end  # class Renderer
end  # module Webby

# EOF
