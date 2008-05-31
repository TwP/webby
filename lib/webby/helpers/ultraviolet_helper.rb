# This code was provided by Guillaume Carbonneau -- http://radr.ca/
# Many thanks for his support of Webby!

if try_require 'uv'

module Webby::Helpers
module UltraVioletHelper

  # The +uv+ method applies syntax highlighting to source code embedded
  # in a webpage. The UltraViolet highlighting engine is used for the HTML
  # markup of the source code. The page sections to be highlighted are given
  # as blocks of text to the +uv+ method.
  #
  # Options can be passed to the UltraViolet engine via attributes in the
  # +uv+ method.
  #
  #    <% uv( :lang => "ruby", :line_numbers => true ) do -%>
  #    # Initializer for the class.
  #    def initialize( string )
  #      @str = string
  #    end
  #    <% end -%>
  #    
  # The supported UltraViolet options are the following:
  #
  #    :lang           : the language to highlight (ruby, c, html, ...)
  #                      [defaults to 'ruby']
  #    :line_numbers   : true or false [defaults to false]
  #    :theme          : see list of available themes in ultraviolet
  #                      [defaults to 'mac_classic']
  #
  # The defaults can be overridden for an entire site by changing the SITE.uv
  # options hash in the Rakefile.
  #
  def uv( *args, &block )
    opts = args.last.instance_of?(Hash) ? args.pop : {}

    text = capture_erb(&block)
    return if text.empty?
    
    defaults = ::Webby.site.uv
    lang = opts.getopt(:lang, defaults[:lang])
    line_numbers = opts.getopt(:line_numbers, defaults[:line_numbers])
    theme = opts.getopt(:theme, defaults[:theme])
    
    out = '<div class="UltraViolet">'
    out << Uv.parse(text, "xhtml", lang, line_numbers, theme)
    out << '</div>'

    # put some guards around the output (specifically for textile)
    out = _guard(out)

    concat_erb(out, block.binding)
    return
  end
end  # module UltraVioletHelper

register(UltraVioletHelper)

end  # module Webby::Helpers
end  # try_require

# EOF
