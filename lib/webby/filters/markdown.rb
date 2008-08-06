
# Render text via markdown using the RDiscount library.
if try_require 'rdiscount'

  Webby::Filters.register :markdown do |input|
    RDiscount.new(input).to_html
  end

# Otherwise raise an error if the user tries to use markdown
else
  Webby::Filters.register :markdown do |input|
    raise Webby::Error, "'rdiscount' must be installed to use the markdown filter"
  end
end

# EOF
