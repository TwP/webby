try_require 'haml'

# Render text via the Haml library
Webby::Filters.register :haml do |input, cursor|
  opts = cursor.page.haml_options || ::Webby.site.haml_options
  b = cursor.renderer.get_binding
  Haml::Engine.new(input, opts).to_html(b)
end

# EOF
