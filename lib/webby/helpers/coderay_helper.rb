if try_require 'coderay'
require 'enumerator'

Loquacious.configuration_for(:webby) {
  desc <<-__
    Options for CodeRay syntax highlighting. See the CodeRay home page
    (http://coderay.rubychan.de/) for more information about the available
    options.
  __
  coderay {
    desc 'The language being highlighted (given as a symbol).'
    lang :ruby

    desc 'Include line numbers in :table, :inline, :list or nil (no line numbers).'
    line_numbers nil

    desc 'Where to start line number counting.'
    line_number_start 1

    desc 'Make every N-th number appear bold.'
    bold_every 10

    desc 'Tabs will be converted into this number of space characters.'
    tab_width 8
  }
}

module Webby::Helpers
module CodeRayHelper

  # The +coderay+ method applies syntax highlighting to source code embedded
  # in a webpage. The CodeRay highlighting engine is used for the HTML
  # markup of the source code. The page sections to be highlighted are given
  # as blocks of text to the +coderay+ method.
  #
  # Options can be passed to the CodeRay engine via attributes in the
  # +coderay+ method.
  #
  #    <% coderay( :lang => "ruby", :line_numbers => "inline" ) do -%>
  #    # Initializer for the class.
  #    def initialize( string )
  #      @str = stirng
  #    end
  #    <% end -%>
  #    
  # The supported CodeRay options are the following:
  #
  #    :lang               : the language to highlight (ruby, c, html, ...)
  #    :line_numbers       : include line numbers in 'table', 'inline',
  #                          or 'list'
  #    :line_number_start  : where to start with line number counting
  #    :bold_every         : make every n-th number appear bold
  #    :tab_width          : convert tab characters to n spaces
  #
  def coderay( *args, &block )
    opts = args.last.instance_of?(Hash) ? args.pop : {}

    text = capture_erb(&block)
    return if text.empty?

    defaults = ::Webby.site.coderay
    lang = opts.getopt(:lang, defaults.lang).to_sym

    cr_opts = {}
    %w(line_numbers       to_sym
       line_number_start  to_i
       bold_every         to_i
       tab_width          to_i).each_slice(2) do |key,convert|
      key = key.to_sym
      val = opts.getopt(key, defaults[key])
      next if val.nil?
      cr_opts[key] = val.send(convert)
    end

    #cr.swap(CodeRay.scan(text, lang).html(opts).div)
    out = %Q{<div class="CodeRay">\n<pre>}
    out << ::CodeRay.scan(text, lang).html(cr_opts)
    out << %Q{</pre>\n</div>}

    # put some guards around the output (specifically for textile)
    out = _guard(out)

    concat_erb(out, block.binding)
    return
  end
end  # module CodeRayHelper

register(CodeRayHelper)

end  # module Webby::Helpers
end  # try_require

# EOF
