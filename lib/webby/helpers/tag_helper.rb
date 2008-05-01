require 'erb'
require 'set'

# :stopdoc:
class ERB
  module Util
    HTML_ESCAPE = { '&' => '&amp;', '"' => '&quot;', '>' => '&gt;', '<' => '&lt;' }

    def html_escape(s)
      s.to_s.gsub(/[&\"><]/) { |special| HTML_ESCAPE[special] }
    end
  end
end
# :startdoc:

module Webby::Helpers

# Provides methods to generate HTML tags programmatically.
# By default, they output XHTML compliant tags.
#
module TagHelper
  include ERB::Util

  BOOLEAN_ATTRIBUTES = Set.new(%w(disabled readonly multiple))

  # Returns an escaped version of +html+ without affecting existing escaped
  # entities.
  #
  # ==== Examples
  #   escape_once("1 > 2 &amp; 3")
  #   # => "1 &lt; 2 &amp; 3"
  #
  #   escape_once("&lt;&lt; Accept & Checkout")
  #   # => "&lt;&lt; Accept &amp; Checkout"
  #
  def escape_once( html )
    html.to_s.gsub(/[\"><]|&(?!([a-zA-Z]+|(#\d+));)/) { |special| ERB::Util::HTML_ESCAPE[special] }
  end

  private

  def tag_options( options, escape = true )
    unless options.empty?
      attrs = []
      if escape
        options.each do |key, value|
          next if value.nil?
          key = key.to_s
          value = BOOLEAN_ATTRIBUTES.include?(key) ? key : escape_once(value)
          attrs << %Q(#{key}="#{value}")
        end
      else
        attrs = options.map {|key, value| %Q(#{key}="#{value}")}
      end
      %Q( #{attrs.sort * ' '}) unless attrs.empty?
    end
  end

end  # module TagHelper

register(TagHelper)

end  # module Webby::Helpers

# EOF
