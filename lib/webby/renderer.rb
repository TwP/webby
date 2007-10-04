# $Id$

require 'erb'
try_require 'bluecloth'
try_require 'redcloth'
try_require 'haml'
try_require 'sass'
try_require 'paginator'

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
      lyt = layouts.find_by_name obj.layout
      break if lyt.nil?

      @content, str = str, ::Webby::File.read(lyt.path)

      lyt.filter.to_a.each do |filter|
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

    @page.filter.to_a.each do |filter|
      str = self.send(filter + '_filter', str)
    end

    str
  end

  # call-seq:
  #    paginate( items, per_page ) {|item| block}
  #
  def paginate( items, count, &block )
    @pager ||= Paginator.new(items.length, count) do |offset, per_page|
      items[offset,per_page]
    end.first

    @pager.each &block

  rescue NameError
    @log.error 'pagination failed (Paginator not installed?)'
    exit
  end

  # call-seq:
  #    next_page
  #
  def next_page
    return false unless defined? @pager and @pager

    # go to the next page; break out if there is no next page
    @pager = @pager.next
    return false if @pager.nil?

    # set filename based on pager number
    fn = "%s%d" % [@page.filename, @pager.number]
    @page.instance_variable_set :@filename, fn
    @page.instance_variable_set :@dest, nil

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
  rescue NameError
    @log.error 'markdown filter failed (BlueCloth not installed?)'
    exit
  end

  # Render text via textile using the RedCloth library.
  #
  def textile_filter( str )
    RedCloth.new(str).to_html
  rescue NameError
    @log.error 'textile filter failed (RedCloth not installed?)'
    exit
  end

  # Render text via the CodeRay syntax highlighter library.
  #
  def coderay_filter( str )
    CodeRayFilter.new(str).to_html
  rescue NameError
    @log.error 'coderay filter failed (CodeRay not installed?)'
    exit
  end

  # Render text via the Haml library
  #
  def haml_filter( str )
    opts = @page.haml_options || {}
    opts[:locals] ||= {}
    opts[:locals].merge!({:page => @page, :pages => @pages})
    Haml::Engine.new(str, opts).to_html
  rescue NameError
    @log.error 'haml filter failed (Haml not installed?)'
    exit
  end

  # Render text via the Sass library (part of Haml)
  #
  def sass_filter( str )
    opts = @page.sass_options || {}
    Sass::Engine.new(str, opts).render
  rescue NameError
    @log.error 'sass filter failed (Haml not installed?)'
    exit
  end

end  # class Renderer
end  # module Webby

# EOF
