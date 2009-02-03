module Webby
module Filters

# The Slides filter is used to generate an S5 presentation from HTML input
# text. The input HTML is scanned for <h1> tags and slide divs are inserted
# before each <h1> tag found.
#
# When the HTML is rendered into the presentation layout, the result is an
# S5 presentation -- provided that the layout includes the appropriate S5
# javascript and CSS files.
#
class Slides

  START_SLIDE = %{<div class="slide">#$/}
  END_SLIDE   = %{</div>#$/#$/}

  # call-seq:
  #    Slides.new( html )
  #
  # Creates a new slides filter that will operate on the given
  # _html_ string.
  #
  def initialize( str )
    @str = str
    @open = false
  end

  # call-seq:
  #    filter    => html
  #
  # Process the original html document passed to the filter when it was
  # created. The document will be scanned for H1 heading tags and slide
  # divs will be inserted into the page before each H1 tag that is found.
  #
  def filter
    result = []

    @str.split(%r/\<h1/i).each do |slide|
      next if slide.strip.empty?
      result << START_SLIDE << '<h1' << slide << END_SLIDE
    end

    result.join
  end
end  # class Slides

# Insert slide divs into the input HTML text.
#
register :slides do |input|
  Slides.new(input).filter
end

end  # module Filters
end  # module Webby

# EOF
