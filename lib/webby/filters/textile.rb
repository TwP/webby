try_require 'redcloth'

# Render text via textile using the RedCloth library.
Webby::Filters.register :textile do |input|
  RedCloth.new(input, %w(no_span_caps)).to_html
end

# EOF
