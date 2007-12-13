# $Id$

module Webby
module Helpers #:nodoc:

#
#
module UrlHelper

  #
  #    url_for( string, opts = {} ) 
  #    url_for( page, opts ={} )
  #
  # Options
  # 
  #    :escape  => true or false
  #    :anchor  => string
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

  def url_for_page( opts = {} )
    opts = opts.symbolize_keys
    url_opts = opts.delete(:url)

    p = @pages.find(opts)
    raise Webby::Renderer::Error,
          "could not find requested page: #{opts.inspect}" if p.nil?

    self.url_for(p, url_opts)
  end

  #
  #
  def link_to( name, *args )
    opts = Hash === args.last ? args.pop : {}
    url = args.first
    attrs = opts.delete(:attrs)

    url = case url
      when String
        url
      when Webby::Resource
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
    "<a #{href_attr}#{attrs}>#{name || url}</a>"
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
  # attribute. If the _name_ is omitted, then either the page +title+
  # attribute or the page +filename+ attribute is used as the name (in that
  # order of preference).
  #
  # Pages are found using key/value pairs. The key is any of the page
  # attributes, and the value is what that attribute should be. Any number
  # of key/value pairs can be included, but all values must match the
  # corresponding page attributes for a match to be found -- i.e. the
  # comparisons are joined by AND operations to determin a match.
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
  def link_to_page( *args )
    self.link_to(*_find_page(args))
  end

  #
  #
  def link_to_page_unless_current( *args )
    name, page, link_opts = _find_page(args)
    return name if @page == page

    self.link_to(name, page, link_opts)
  end

  
  private

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

    name = h(p.title || p.filename) if name.nil?
    return [name, p, link_opts]
  end

end  # module UrlHelper
end  # module Helpers
end  # module Webby

# EOF
