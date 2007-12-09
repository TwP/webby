# $Id$

module Webby
module Helpers #:nodoc:

#
#
module UrlHelper

  #
  #    url_for(:page => { :title => 'Home Page' })
  #
  def url_for( opts = {} )
    escape, anchor = true, nil

    case opts
    when String
      url = opts
    when Webby::Resource
      url = opts.url
    else
      anchor = opts.delete(:anchor)
      escape = opts.delete(:escape) if opts.has_key?(:escape)

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
  def link_to( *args )
    opts = Hash === args.last ? args.pop : {}
    name, url = args.compact
    attrs = opts.delete(:attrs)

    case url
    when String; nil
    when :back
      url = 'javascript:history.back()'
    else
      case name
      when String
        if opts.has_key? :page
          url = self.url_for(opts)
        else
          p = @pages.find(:title => name) ||
              @pages.find(:filename => name)
          url = p.nil? ? self.url_for(name) : self.url_for(p)
        end

      when Webby::Resource
        name = name.title || name.filename
        url = self.url_for(name)

      else
        unless opts.has_key?(:page)
          raise Webby::Renderer::Error,
                "a name, URL, or a page to find must be given"
        end

        p = @pages.find(opts[:page])
        raise Webby::Renderer::Error,
              "could not find requested page: #{opts.inspect}" if p.nil?

        name = p.title || p.filename
        url = self.url_for(p)
      end
    end

    if attrs
      html_opts = attrs.stringify_keys
      href = html_opts.has_key?('href')
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
