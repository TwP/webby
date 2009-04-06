
# Render text via the Haml library
if try_require('haml', 'haml')

  Loquacious.configuration_for(:webby) {
    desc <<-__
      A hash of options that will be passed to the Haml::Engine when procesing
      content through the 'haml' filter. See the Haml rdoc documentation for
      the list of available options.

      Note: webby will set the :filename to the current page being rendered.
    __
    haml_options Hash.new
  }

  Webby::Filters.register :haml do |input, cursor|
    opts = ::Webby.site.haml_options.merge(cursor.page.haml_options || {})
    opts = opts.symbolize_keys
    opts.merge!(:filename => cursor.page.destination)
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
