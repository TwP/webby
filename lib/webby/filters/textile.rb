# Render text via textile using the RedCloth library.
Webby::Filters.register :textile do |input|
  RedCloth.new(input).to_html
end