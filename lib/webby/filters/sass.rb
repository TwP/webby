
# Render text via the Sass library (part of Haml)
if try_require('sass', 'haml')

  Loquacious.configuration_for(:webby) {
    desc <<-__
      A hash of options that will be passed to the Sass::Engine when procesing
      content through the 'sass' filter. See the Sass rdoc documentation for
      the list of available options (par of the haml gem).

      Note: webby will set the :filename to the current page being rendered.
    __
    sass_options Hash.new
  }

  Webby::Filters.register :sass do |input, cursor|
    opts = ::Webby.site.sass_options.merge(cursor.page.sass_options || {})
    opts = opts.symbolize_keys
    opts.merge!(:filename => cursor.page.destination)
    opts[:style] = opts[:style].to_sym if opts.include? :style
    Sass::Engine.new(input, opts).render
  end

# Otherwise raise an error if the user tries to use sass
else
  Webby::Filters.register :sass do |input, cursor|
    raise Webby::Error, "'haml' must be installed to use the sass filter"
  end
end

# EOF
