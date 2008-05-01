require 'erb'

# Render text via ERB using the built in ERB library.
Webby::Filters.register :erb do |input, cursor|
  b = cursor.renderer.get_binding
  ERB.new(input, nil, '-').result(b)
end

# EOF
