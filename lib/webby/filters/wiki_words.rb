
Webby::Filters.register :wikiwords do |input, cursor|

  renderer = cursor.renderer
  input.gsub %r/\[\[([^\]]+)\]\]/ do
    name = $1
    renderer.link_to_page(name) {
      %Q(<a class="missing internal">#{name}</a>)
    }
  end

end

# EOF
