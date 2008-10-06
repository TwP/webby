
module Webby

# The Journal class is used to output simple messages regarding the creation
# and updating of files when webby applications are run. The output messages
# will be color coded if the terminal supports the ANSI codes.
#
class Journal

  attr_accessor :colorize
  attr_reader :logger

  # Create a new journal
  #
  def initialize
    @logger = ::Logging::Logger[self]
    @colorize = ENV.has_key?('TERM')
  end

  # Output a message of the given _type_ using the option _color_ code. The
  # available codes are as follows:
  #
  # * black
  # * red
  # * green
  # * yellow
  # * blue
  # * magenta
  # * cyan
  # * white
  #
  # The color is specified as a string or a symbol.
  #
  def typed_message( type, msg, color = nil )
    type = type.to_s.rjust(13)
    type = self.send(color, type) unless color.nil?
    logger.info "#{type}  #{msg.to_s}"
  end

  # Output a "create" message or an "update" message depending on whether
  # the given _page_ already has a generated output file or not.
  #
  def create_or_update( page )
    if test(?e, page.destination)
      update(page.destination)
    else
      create(page.destination)
    end
  end

  # Output a create message.
  #
  def create( msg )
    typed_message('create', msg, (colorize ? :green : nil))
  end

  # Output an update message.
  #
  def update( msg )
    typed_message('update', msg, (colorize ? :yellow : nil))
  end

  # Output a force message.
  #
  def force( msg )
    typed_message('force', msg, (colorize ? :red : nil))
  end

  # Output a skip message.
  #
  def skip( msg )
    typed_message('skip', msg, (colorize ? :yellow : nil))
  end

  # Output an exists message.
  #
  def exists( msg )
    typed_message('exists', msg, (colorize ? :cyan : nil))
  end

  # Output an identical message.
  #
  def identical( msg )
    typed_message('identical', msg, (colorize ? :cyan : nil))
  end

  [ [ :clear        ,   0 ],
    [ :reset        ,   0 ],     # synonym for :clear
    [ :bold         ,   1 ],
    [ :dark         ,   2 ],
    [ :italic       ,   3 ],     # not widely implemented
    [ :underline    ,   4 ],
    [ :underscore   ,   4 ],     # synonym for :underline
    [ :blink        ,   5 ],
    [ :rapid_blink  ,   6 ],     # not widely implemented
    [ :negative     ,   7 ],     # no reverse because of String#reverse
    [ :concealed    ,   8 ],
    [ :strikethrough,   9 ],     # not widely implemented
    [ :black        ,  30 ],
    [ :red          ,  31 ],
    [ :green        ,  32 ],
    [ :yellow       ,  33 ],
    [ :blue         ,  34 ],
    [ :magenta      ,  35 ],
    [ :cyan         ,  36 ],
    [ :white        ,  37 ],
    [ :on_black     ,  40 ],
    [ :on_red       ,  41 ],
    [ :on_green     ,  42 ],
    [ :on_yellow    ,  43 ],
    [ :on_blue      ,  44 ],
    [ :on_magenta   ,  45 ],
    [ :on_cyan      ,  46 ],
    [ :on_white     ,  47 ] ].each do |name,code|

    class_eval <<-CODE
      def #{name.to_s}( str )
        "\e[#{code}m\#{str}\e[0m"
      end
    CODE
  end

end  # class Journal
end  # module Webby

# EOF
