if try_require 'redcloth'

require 'htmlentities'

module Webby::Helpers
module TextileCode

  # This method defines a "code." tag in textile documents. The tag is used
  # to apply UltraViolet syntax highlighting to a chunk of text. The text
  # can be either inlined in the document or slurped in from a Webby
  # partial.
  #
  # ==== Examples
  #
  # In this example, the site-wide default settings are used to determine
  # language, line numbering and UV theme.
  #
  #   code. 
  #   class Object
  #     def returning( obj, &block )
  #       block.call obj
  #       return obj
  #     end
  #   end
  #
  # Options can be passed to the code. tag itself using Ruby hash sytax.
  #
  #   code. {:lang => 'ragel', :line_numbers => false}
  #   action dgt      { printf("DGT: %c\n", fc); }
  #   action dec      { printf("DEC: .\n"); }
  #   action exp      { printf("EXP: %c\n", fc); }
  #   action exp_sign { printf("SGN: %c\n", fc); }
  #   action number   { /*NUMBER*/ }
  #   number = (
  #       [0-9]+ $dgt ( '.' @dec [0-9]+ $dgt )?
  #           ( [eE] ( [+\-] $exp_sign )? [0-9]+ $exp )?
  #           ) %number;
  #   main := ( number '\n' )*;
  #
  def textile_code( tag, atts, cite, content )
    rgxp = %r/class="([^\"]*)"/
    atts = if atts.match(rgxp)
             atts.sub(rgxp, %{class="UltraViolet \1"})
           else
             [atts, 'class="UltraViolet"'].join(' ')
           end

    # remove the first line of text from the content
    content = content.sub(%r/^([^#$/]*)#$/?/m, '')
    header = $1.strip

    # try to match for an external "partial {opts}"
    m = %r/([^\{]*)?\s*(\{.*\})?/.match header
    filename, opts = m.to_a.last(2)

    # grab the options to pass to the UltraViolet syntax highlighter
    opts = opts ? eval(opts) : {}
    defaults = ::Webby.site.uv

    # try to find the partial if a filename was given
    unless filename.empty?
      partial = @_renderer._find_partial(filename.strip)
      content << @_renderer.render_partial(partial)

      h = {}
      %w[lang line_numbers theme].each do |key|
        v = partial[key]
        h[key.to_sym] = v unless v.nil?
      end
      defaults = defaults.merge(h)
    end

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

# FIXME: it appears that RedCloth is going to insert span tags into the rendered code blocks
#         -- so I'm removing this functionality for# the time being (which makes me very sad)
#
RedCloth.__send__(:include, TextileCode)

end  # module Webby::Helpers
end  # if try_require

# EOF
