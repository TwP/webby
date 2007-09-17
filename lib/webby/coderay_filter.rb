# $Id$

require 'enumerator'
require 'hpricot'
try_require 'coderay'

module Webby

# The CodeRayFilter applies syntax highlighting to source code embedded in a
# webpage. The CodeRay highlighting engine is used for the HTML markup of
# the source code. A set of <coderay>...</coderay> tags is used to denote
# which sections of the page should be highlighted.
#
# Options can be passed to the CodeRay engine via attributes in the
# <coderay> tag.
#
#    <coderay lang="ruby" line_numbers="inline">
#    # Initializer for the class.
#    def initialize( string )
#      @str = stirng
#    end
#    </coderay>
#    
#  The supported CodeRay options are the following:
#
#    line_numbers       : include line nubers in 'table', 'linline',
#                         or 'list'
#    line_number_start  : where to start with line number counting
#    bold_every         : make every n-th number appear bold
#    tab_width          : convert tab characters to n spaces
#     
class CodeRayFilter

  # call-seq:
  #    CodeRayFilter.new( string )
  #
  # Creates a new CodeRay filter that will operate on the given _string_.
  #
  def initialize( str )
    @str = str
  end

  # call-seq:
  #    to_html    => string
  #
  # Process the original text string passed to the filter when it was
  # created and output HTML formatted text. Any text between
  # <coderay>...</coderay> tags will have syntax highlighting applied to the
  # text via the CodeRay gem.
  #
  def to_html
    doc = Hpricot(@str)
    doc.search('//coderay') do |cr|
      text = cr.inner_html.strip
      lang = (cr['lang'] || 'ruby').to_sym

      opts = {}
      %w(line_numbers       to_sym
         line_number_start  to_i
         bold_every         to_i
         tab_width          to_i).each_slice(2) do |key,convert|
        next if cr[key].nil?
        opts[key.to_sym] = cr[key].send(convert)
      end

      #cr.swap(CodeRay.scan(text, lang).html(opts).div)
      out = "<div class=\"CodeRay\"><pre>\n"
      out << CodeRay.scan(text, lang).html(opts)
      out << "\n</pre></div>"
      cr.swap out
    end

    doc.to_html
  end

end  # class CodeRayFilter
end  # module Webby

# EOF
