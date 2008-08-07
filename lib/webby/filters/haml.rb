
# Render text via the Haml library
if try_require('haml', 'haml')

  Webby::Filters.register :haml do |input, cursor|
    opts = ::Webby.site.haml_options.merge(cursor.page.haml_options || {})
    b = cursor.renderer.get_binding
    Haml::Engine.new(input, opts).to_html(b)
  end

# Otherwise raise an error if the user tries to use haml
else
  Webby::Filters.register :haml do |input, cursor|
    raise Webby::Error, "'haml' must be installed to use the haml filter"
  end
end

# EOF
