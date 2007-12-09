# $Id$

module Webby
module Helpers #:nodoc:

#
#
module UrlHelper

  #
  #    url_for( string, opts = {} ) 
  #    url_for( page, opts ={} )
  #    url_for( :page => { :title => 'Home Page' }, opts = {} )
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

    case obj
    when String
      by = Webby.site.find_by.to_sym
      p = @pages.find(by => obj)
      url = p.nil? ? obj : p.url
    when Webby::Resource
      url = obj.url
    else
      p = @pages.find(opts[:page])
      raise Webby::Renderer::Error,
            "could not find requested page: #{opts.inspect}" if p.nil?
      url = p.url
    end

    url = escape_once(url) if escape
    url << "#" << anchor if anchor

    return url
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
        self.url_for(url)
      when :back
        'javascript:history.back()'
      else
        if opts.has_key? :page
          self.url_for(opts)
        else
          self.url_for(name)
        end
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
    "<a #{href_attr}#{attrs}>#{name}</a>"
  end

end  # module UrlHelper
end  # module Helpers
end  # module Webby

# EOF
