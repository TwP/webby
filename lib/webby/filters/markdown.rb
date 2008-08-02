try_require 'rdiscount'

# Render text via markdown using the RDiscount library.
Webby::Filters.register :markdown do |input|
  RDiscount.new(input).to_html
end

# EOF
