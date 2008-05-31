try_require 'redcloth'

# Render text via textile using the RedCloth library.
Webby::Filters.register :textile do |input, cursor|
  rc = RedCloth.new(input, %w(no_span_caps))
  rc.instance_variable_set(:@_renderer, cursor.renderer)
  rc.to_html
end

# EOF
