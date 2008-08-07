
# If RedCloth is installed, then configure the textile filter
if try_require('redcloth', 'RedCloth')

  Webby::Filters.register :textile do |input|
    RedCloth.new(input, %w(no_span_caps)).to_html
  end

# Otherwise raise an error if the user tries to use textile
else
  Webby::Filters.register :textile do |input|
    raise Webby::Error, "'RedCloth' must be installed to use the textile filter"
  end
end

# EOF
