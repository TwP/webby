if try_require 'redcloth'

require 'htmlentities'

module Webby::Helpers
module TextileCode

  #
  #
  #
  def textile_code( tag, atts, cite, content )
    rgxp = %r/class="([^\"]*)"/
    atts = if atts.match(rgxp)
             atts.sub(rgxp, %{class="UltraViolet \1"})
           else
             [atts, 'class="UltraViolet"'].join(' ')
           end

    # remove the first line of text from the content
    content = content.sub(%r/^([^#$/]*)#$//m, '')
    header = $1.strip

    # try to match for an external "filename[part] {opts}"
    m = %r/([^\[\{]*)?(?:\[([^\{]*)\])?\s*(\{.*\})?/.match header
    filename, part, opts = m.to_a.last(3)

    # grab the options to pass to the UltraViolet syntax highlighter
    opts = opts ? eval(opts) : {}
    defaults = ::Webby.site.uv

    lang = opts.getopt(:lang, defaults[:lang])
    line_numbers = opts.getopt(:line_numbers, defaults[:line_numbers])
    theme = opts.getopt(:theme, defaults[:theme])

    # run the UltraViolet syntax highlighter on the content
    # we have to decode the HTML entities that UltraViolet encoded because
    # RedCloth is going to do the exact same encoding again
    content = Uv.parse(content, "xhtml", lang, line_numbers, theme)
    content = HTMLEntities.new.decode(content)

    %{
    <div #{atts}>
    #{content}
    </div>
    }
  end
end  # module TextileCode

RedCloth.__send__(:include, TextileCode)

end  # module Webby::Helpers
end  # if try_require

# EOF
