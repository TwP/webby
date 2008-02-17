# $Id$

module Webby
module Helpers #:nodoc:

#
#
module UrlHelper

  # call-seq:
  #    url_for( name, opts = {} ) 
  #
  # Creates a URL for the given _name_ and _opts_. If _name_ is a string
  # then it is used as the URL base. If _name_ is a Resource then it is
  # converted to a URL by calling its +url+ method.
  #
  # ==== Options
  # 
  # * <tt>:escape</tt> -- determines whether the returned URL will be HTML escaped or not (+true+ by default)
  # * <tt>:anchor</tt> -- specifies the anchor name to be appended to the path
  #
  # ==== Examples
  #
  #    <%= url_for('/some/page.html') %>
  #    # => /some/page
  #
  #    <%= url_for('/some/page.html', :anchor => 'tidbit') %>
  #    # => /some/page#tidbit
  #
  #    <%= url_for(@page) %>
  #    # => /current/page.html
  #
  #    <%= url_for(@page, :anchor => 'this&that') %>
  #    # => /current/page.html#this&amp;that
  #
  def url_for( *args )
    opts = Hash === args.last ? args.pop : {}
    obj = args.first

    anchor = opts.delete(:anchor)
    escape = opts.has_key?(:escape) ? opts.delte(:escape) : true

    url = Webby::Resource === obj ? obj.url : obj.to_s
    url = escape_once(url) if escape
    url << "#" << anchor if anchor

    return url
  end

  # call-seq:
  #    url_for_page( :key => value, :url => {} )
  #
  # Creates a URL for the page identified by the set of <em>:key /
  # value</em> pairs. The <em>:url</em> options are passed to the url_for
  # method for final URL creation; see the url_for method for
  # documentation on those options.
  #
  # The PagesDB#find method is used to locate the page; see the find method
  # for the available options.
  #
  # ==== Examples
  #
  #    <%= url_for_page(:title => 'Funny Story', :anchor => 'punchline') %>
  #    # => /humor/funny_story.html#punchline
  #
  def url_for_page( opts = {} )
    opts = opts.symbolize_keys
    url_opts = opts.delete(:url)

    p = @pages.find(opts)
    raise Webby::Renderer::Error,
          "could not find requested page: #{opts.inspect}" if p.nil?

    self.url_for(p, url_opts)
  end

  # call-seq:
  #    link_to( name, url, :attrs => {} )
  #
  # Create an HTTP anchor tag with 
  #
  # url can be a url string, a page, :back, or nothing
  #
  # :attrs are used to generate HTML anchor tag attributes
  #
  # ==== Examples
  #
  #    <%= link_to('Google', 'http://www.google.com/', :attrs => {:name => 'google'}) %>
  #    # => <a href="http://www.google.com/" name="google">Google</a>
  #
  #    <%= link_to('A Page', @page, :anchor => 'blah') %>
  #    # => <a href="/a/page.html#blah">A Page</a>
  #
  def link_to( name, *args )
    opts = Hash === args.last ? args.pop : {}
    url = args.first
    attrs = opts.delete(:attrs)

    url = case url
      when String, Webby::Resource
        self.url_for(url, opts)
      when :back
        'javascript:history.back()'
      else
        self.url_for(name, opts)
      end

    if attrs
      html_opts = attrs.stringify_keys
      href = html_opts.has_key? 'href'
      attrs = tag_options(html_opts)
    else
      href = false
      attrs = nil
    end

    href_attr = href ? nil : %Q(href="#{url}")
    "<a #{href_attr}#{attrs}>#{name || h(url)}</a>"
  end

  # call-seq:
  #    link_to_page( name )
  #    link_to_page( :key => value )
  #    link_to_page( name, :key => value )
  #    link_to_page( page )
  #
  # Creates a link tag of the given _name_ using a URL created by finding
  # the associated page from the key/value pairs. If the key/value pairs are
  # omitted, the _name_ is used in conjunction with the default site +find_by+
  # attribute. Unless changed by the user, the default +find_by+ attribute
  # is the page title.
  #
  # Pages are found using key/value pairs. The key is any of the page
  # attributes, and the value is what that attribute should be. Any number
  # of key/value pairs can be included, but all values must equal the
  # corresponding page attributes for a match to be found -- i.e. the
  # comparisons are joined by AND operations to determine a match.
  #
  # In the absence of any key/value pairs -- just a name was given -- then
  # the default site +find_by+ attribute is used, and the name is compared
  # against this attribute from the page. The default +find_by+ attribue is
  # set in the Rakefile or in the <tt>Webby.site.find_by</tt> parameter.
  #
  # Several options can be passed to the method to determin how URLs are
  # created and to specify any HTML attributes on the returned link tag. The
  # URL options are given as a hash to the <tt>:url</tt> key. The HTML
  # attributes are given as a hash to the <tt>:attrs</tt> key.
  #
  # See the +url_for+ method for a desciption of the <tt>:url</tt> options.
  # See the +link_to+ method for a description of the <tt>:attrs</tt>
  # options.
  #
  # ==== Examples
  #
  #    <%= link_to_page('Funny Story', :url => {:anchor => 'punchline'}) %>
  #    # => <a href="/humor/funny_story.html#punchline">Funny Story</a>
  #
  #    <%= link_to_page('Hilarious', :title => 'Funny Story') %>
  #    # => <a href="/humor/funn_story.html">Hilarious</a>
  #
  def link_to_page( *args )
    self.link_to(*_find_page(args))
  end

  # call-seq:
  #    link_to_page_unless_current( name )
  #    link_to_page_unless_current( :key => value )
  #    link_to_page_unless_current( name, :key => value )
  #    link_to_page_unless_current( page )
  #
  # This function operates in the same fashion as the +link_to_page+ fuction
  # with the exception that if the page to be linked to is the current page,
  # then only the _name_ is rendered without an HTML anchor tag.
  #
  # ==== Examples
  #
  #    <%= link_to_page_unless_current('Funny Story') %>
  #    # => <a href="/humor/funny_story.html">Funny Story</a>
  #
  #    <%= link_to_page_unless_current(@page) %>
  #    # => This Page
  #
  def link_to_page_unless_current( *args )
    name, page, link_opts = _find_page(args)
    return name if @page == page

    self.link_to(name, page, link_opts)
  end

  
  private

  # call-seq:
  #    _find_page( name, opts = {}  )
  #    _find_page( :key => value, [:key => value, ...], opts = {}  )
  #    _find_page( name, :key => value, [:key => value, ...], opts = {} )
  #    _find_page( page, opts = {} )
  #
  # Returns an array of the [name, page, options]. 
  #
  # ==== Options
  # 
  # * <tt>:url</tt> -- hash of options for the +url_for+ method
  # * <tt>:attrs</tt> -- hash of options for the +link_to+ method
  #
  def _find_page( args )
    raise ArgumentError, 'wrong number of arguments (0 for 1)' if args.empty?

    opts = Hash === args.last ? args.pop : {}
    name = args.first
    link_opts = opts.delete(:url) || {}
    link_opts[:attrs] = opts.delete(:attrs)

    if Webby::Resource === name
      p, name = name, nil
    elsif opts.empty? && name
      p = @pages.find(Webby.site.find_by.to_sym => name)
    else
      p = @pages.find(opts)
    end

    raise Webby::Renderer::Error,
          "could not find requested page: #{opts.inspect}" if p.nil?

    name = p.title || p.filename if name.nil?
    return [h(name), p, link_opts]
  end

end  # module UrlHelper

register(UrlHelper)

end  # module Helpers
end  # module Webby

# EOF
