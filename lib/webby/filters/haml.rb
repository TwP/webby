# $Id$

try_require 'haml'

# Render text via the Haml library
Webby::Filters.register :haml do |input, cursor|
  opts = cursor.page.haml_options || {}
  opts[:locals] ||= {}
  opts[:locals].merge!(
    :page => cursor.renderer.page,
    :pages => cursor.renderer.pages
  )
  Haml::Engine.new(input, opts).to_html
end

# EOF
