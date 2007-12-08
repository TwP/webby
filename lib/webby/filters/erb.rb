# Render text via ERB using the built in ERB library.
Webby::Filters.register :erb do |input, cursor|
  @page = cursor.page
  @content = cursor.renderer.content
  ERB.new(input, nil, '-').result(binding)
end