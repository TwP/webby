# $Id$

require 'erb'

module Webby

#
#
class Renderer
  include ERB::Util

  # call-seq:
  #    Renderer.new( page )
  #
  def initialize( page )
    unless page.is_page?
      raise ArgumentError,
            "only page resources can be rendered '#{page.path}'"
    end

    @page = page
    @pages = Resource.pages
    @content = nil
  end

  def layout_page
    layouts = Resource.layouts
    obj = @page
    str = @page.render

    loop do
      lyt = layouts.find_by_name obj.layout
      break if lyt.nil?

      @content, str = str, ::Webby::File.read(lyt.path)

      lyt.filter.to_a.each do |filter|
        str = self.send(filter + '_filter', str)
      end

      @content, obj = nil, lyt
    end

    str
  end

  # call-seq:
  #    render_page
  #
  def render_page
    str = ::Webby::File.read(@page.path)

    @page.filter.to_a.each do |filter|
      str = self.send(filter + '_filter', str)
    end

    str
  end

  def erb_filter( str )
    b = binding
    ERB.new(str, nil, '-').result(b)
  end

end  # class Renderer
end  # module Webby

# EOF
