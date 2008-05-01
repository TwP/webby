try_require 'bluecloth'

# Render text via markdown using the BlueCloth library.
Webby::Filters.register :markdown do |input|
  BlueCloth.new(input).to_html
end

# EOF
