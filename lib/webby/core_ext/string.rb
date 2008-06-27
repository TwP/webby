
class String

  def self.small_words
    @small_words ||= %w(a an and as at but by en for if in of on or the to v[.]? via vs[.]?)
  end

  def /( path )
    ::File.join(self, path)
  end

  def titlecase
    swrgxp = self.class.small_words.join('|')

    parts = self.split( %r/( [:.;?!][ ] | (?:[ ]|^)["“] )/x )
    parts.each do |part|
      part.gsub!(%r/\b[[:alpha:]][[:lower:].'’]*\b/) do |s|
        s =~ %r/\w+\.\w+/ ? s : s.capitalize
      end

      # Lowercase the small words
      part.gsub!(%r/\b(#{swrgxp})\b/i) {|w| w.downcase}

      # If the first word is a small word, then capitalize it
      part.gsub!(%r/\A([[:punct:]]*)(#{swrgxp})\b/) {$1 + $2.capitalize}

      # If the last word is a small word, then capitalize it
      part.gsub!(%r/\b(#{swrgxp})([^\w\s]*)\z/) {$1.capitalize + $2}
    end

    str = parts.join

    # Special cases:
    str.gsub!(/ V(s?)\. /, ' v\1. ')               # "v." and "vs."
    str.gsub!(/(['’])S\b/, '\1s')                  # 'S (otherwise you get "the SEC'S decision")
    str.gsub!(/\b(AT&T|Q&A)\b/i) { |w| w.upcase }  # "AT&T" and "Q&A", which get tripped up.

    str
  end
end  # class String

# EOF
