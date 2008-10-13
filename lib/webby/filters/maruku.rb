
# Render text via markdown using the Maruku library.
if try_require('maruku', 'maruku')

  Webby::Filters.register :maruku do |input|
    Maruku.new(input).to_html
  end

# Otherwise raise an error if the user tries to use maruku
else
  Webby::Filters.register :maruku do |input|
    raise Webby::Error, "'maruku' must be installed to use the maruku filter"
  end
end

# EOF
