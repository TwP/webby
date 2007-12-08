# Render text via the Sass library (part of Haml)
Webby::Filters.register :sass do |input, cursor|
  opts = cursor.page.sass_options || {}
  Sass::Engine.new(input, opts).render
end