# $Id$

require 'erb'

try_require 'bluecloth'
try_require 'redcloth'

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

  # call-seq:
  #    layout_page
  #
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

  # Render text via ERB using the built in ERB library.
  #
  def erb_filter( str )
    b = binding
    ERB.new(str, nil, '-').result(b)
  end

  # Render text via markdown using the BlueCloth library.
  #
  def markdown_filter( str )
    BlueCloth.new(str).to_html
  rescue NameError
    $stderr.puts 'ERROR: markdown filter failed (BlueCloth not installed?)'
    exit
  end

  # Render text via textile using the RedCloth library.
  #
  def textile_filter( str )
    RedCloth.new(str).to_html
  rescue NameError
    $stderr.puts 'ERROR: textile filter failed (RedCloth not installed?)'
    exit
  end

end  # class Renderer
end  # module Webby

# EOF
