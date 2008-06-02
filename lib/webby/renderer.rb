# Equivalent to a header guard in C/C++
# Used to prevent the spec helper from being loaded more than once
unless defined? ::Webby::Renderer

require 'erb'

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

  # :stopdoc:
  @@stack = []
  # :startdoc:

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
        fd.write(renderer.__send__(:_layout_page))
      end
      break unless renderer.__send__(:_next_page)
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
    unless page.instance_of? Resources::Page
      raise ArgumentError,
            "only page resources can be rendered '#{page.path}'"
    end

    @page = page
    @pages = Resources.pages
    @partials = Resources.partials
    @content = nil
    @config = ::Webby.site

    @_bindings = []
    @_content_for = {}
    @log = Logging::Logger[self]
  end

  # call-seq:
  #    render( resource = nil, opts = {} )    => string
  #
  # Render the given resource (a page or a partial) and return the results
  # as a string. If a resource is not given, then the options hash should
  # contain the name of a partial to render (:partial => 'name').
  #
  # When a partial name is given, the partial is found by looking in the
  # directory of the current page being rendered. Otherwise, the full path
  # to the partial can be given.
  #
  # If a :guard option is given as true, then the resulting string will be
  # protected from processing by subsequent filters. Currently this only
  # protects against the textile filter.
  #
  # When rendering partials, local variables can be passed to the partial by
  # setting them in hash passed as the :locals option.
  #
  # ==== Options
  # :partial<String>::
  #   The partial to render
  # :locals<Hash>::
  #   Locals values to define when rendering a partial
  # :guard<Boolean>::
  #   Prevents the resulting string from being processed by subsequent
  #   filters (only textile for now)
  # 
  # ==== Returns
  # A string that is the rendered page or partial.
  #
  # ==== Examples
  #    # render the partial "foo" using the given local variables
  #    render( :partial => "foo", :locals => {:bar => "value for bar"} )
  #
  #    # find another page and render it into this page and protect the
  #    # resulting contents from further filters
  #    page = @pages.find( :title => "Chicken Coop" )
  #    render( page, :guard => true )
  #
  #    # find a partial and render it using the given local variables
  #    partial = @partials.find( :filename => "foo", :in_directory => "/path" )
  #    render( partial, :locals => {:baz => "baztastic"} )
  #
  def render( *args )
    opts = Hash === args.last ? args.pop : {}
    resource = args.first
    resource = _find_partial(opts[:partial]) if resource.nil?

    str = case resource
      when Resources::Page
        ::Webby::Renderer.new(resource)._render_page
      when Resources::Partial
        _render_partial(resource, opts)
      else
        raise ::Webby::Error, "expecting a page or a partial but got '#{resource.class.name}'"
      end

    str = _guard(str) if opts[:guard]
    str
  end

  # call-seq:
  #    render_page    => string
  #
  # This method is being deprecated. It is being made internal to the
  # framework and really shouldn't be used anymore.
  #
  def render_page
    Webby.deprecated "render_page", "this method is being made internal to the framework"
    _render_page
  end

  # call-seq:
  #    render_partial( partial, :locals => {} )    => string
  #
  # This method is being deprecated. Please use the +render+ method instead.
  #
  def render_partial( part, opts = {} )
    Webby.deprecated "render_partial", "it is being replaced by the Renderer#render() method"
    opts[:partial] = part
    render opts
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
  # accessed from the page. The <code>@pager</code> contains information
  # about the next page, the current page number, the previous page, and the
  # number of items in the current page.
  #
  def paginate( items, count, &block )
    @pager ||= Paginator.new(items.length, count, @page) do |offset, per_page|
      items[offset,per_page]
    end.first

    @pager.each(&block)
  end

  # call-seq:
  #    get_binding    => binding
  #
  # Returns the current binding for the renderer.
  #
  def get_binding
    @_bindings.last
  end

  # call-seq:
  #    _render_page    => string
  #
  # Apply the desired filters to the page. The filters to apply are
  # determined from the page's meta-data.
  #
  def _render_page
    _track_rendering(@page.path) {
      Filters.process(self, @page, ::Webby::Resources::File.read(@page.path))
    }
  end

  # call-seq:
  #    _render_partial( partial, :locals => {} )    => string
  #
  # Render the given _partial_ into the current page. The :locals are a hash
  # of key / value pairs that will be set as local variables in the scope of
  # the partial when it is rendered.
  #
  def _render_partial( part, opts = {} )
    _track_rendering(part.path) {
      _configure_locals(opts[:locals])
      Filters.process(self, part, ::Webby::Resources::File.read(part.path))
    }
  end

  # call-seq:
  #    _layout_page    => string
  #
  # Apply the desired filters to the page and then render the filtered page
  # into the desired layout. The filters to apply to the page are determined
  # from the page's meta-data. The layout to use is also determined from the
  # page's meta-data.
  #
  def _layout_page
    @content = _render_page

    _track_rendering(@page.path) {
      _render_layout_for(@page)
    }
    raise ::Webby::Error, "rendering stack corrupted" unless @@stack.empty?

    @content
  rescue ::Webby::Error => err
    @log.error "while rendering page '#{@page.path}'"
    @log.error err.message
  rescue => err
    @log.error "while rendering page '#{@page.path}'"
    @log.fatal err
    exit 1
  ensure
    @content = nil
    @@stack.clear
  end

  # call-seq:
  #    _render_layout_for( resource )
  #
  # Render the layout for the given resource. If the resource does not have
  # a layout, then this method returns immediately.
  #
  def _render_layout_for( res )
    return unless res.layout
    lyt = Resources.layouts.find :filename => res.layout
    return if lyt.nil?

    _track_rendering(lyt.path) {
      @content = Filters.process(
          self, lyt, ::Webby::Resources::File.read(lyt.path))
      _render_layout_for(lyt)
    }
  end

  # call-seq:
  #    _next_page    => true or false
  #
  # Returns +true+ if there is a next page to render. Returns +false+ if
  # there is no next page or if pagination has not been configured for the
  # current page.
  #
  def _next_page
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

  # call-seq:
  #    _track_rendering( path ) {block}
  #
  # Keep track of the page rendering for the given _path_. The _block_ is
  # where the the page will be rendered.
  #
  # This method keeps a stack of the current pages being rendeered. It looks
  # for duplicates in the stack -- an indication of a rendering loop. When a
  # rendering loop is detected, an error is raised.
  #
  # This method returns whatever is returned from the _block_.
  #
  def _track_rendering( path )
    loop_error = @@stack.include? path
    @@stack << path
    @_bindings << _binding

    if loop_error
      msg = "rendering loop detected for '#{path}'\n"
      msg << "    current rendering stack\n\t"
      msg << @@stack.join("\n\t")
      raise ::Webby::Error, msg
    end

    yield
  ensure
    @@stack.pop if path == @@stack.last
    @_bindings.pop
  end

  # call-seq:
  #    _configure_locals( locals )
  #
  # Configure local variables in the scope of the current binding returned
  # by the +get_binding+ method. The _locals_ should be given as a hash of
  # name / value pairs.
  #
  def _configure_locals( locals )
    return if locals.nil?

    locals.each do |k,v|
      Thread.current[:value] = v
      definition = "#{k} = Thread.current[:value]"
      eval(definition, get_binding)
    end
  end

  # Attempts to locate a partial by name. If only the partial name is given,
  # then the current directory of the page being rendered is searched for
  # the partial. If a full path is given, then the partial is searched for
  # in that directory.
  #
  # Raies a Webby::Error if the partial could not be found.
  #
  def _find_partial( part )
    case part
    when String
      part_dir = ::File.dirname(part)
      part_dir = @page.dir if part_dir == '.'

      part_fn = ::File.basename(part)
      part_fn = '_' + part_fn unless part_fn =~ %r/^_/

      p = Resources.partials.find(
          :filename => part_fn, :in_directory => part_dir ) rescue nil
      raise ::Webby::Error, "could not find partial '#{part}'" if p.nil?
      p
    when ::Webby::Resources::Partial
      part
    else raise ::Webby::Error, "expecting a partial or a partial name" end
  end

  # This method will put filter guards around the given input string. This
  # will protect the string from being processed by any remaining filters
  # (specifically the textile filter).
  #
  # The string is returned unchanged if there are no remaining filters to
  # guard against.
  #
  def _guard( str )
    return str unless @_cursor

    if @_cursor.remaining_filters.include? 'textile'
      str = "<notextile>\n%s\n</notextile>" % str
    end
    str
  end

  # Returns the binding in the scope of this Renderer object.
  #   
  def _binding() binding end

end  # class Renderer
end  # module Webby

Webby.require_all_libs_relative_to(__FILE__, 'stelan')

end  # unless defined?

# EOF
