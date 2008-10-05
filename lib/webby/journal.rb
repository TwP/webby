
begin require 'facets/ansicode'; rescue LoadError; end

module Webby

# The Journal class is used to output simple messages regarding the creation
# and updating of files when webby applications are run. The output messages
# will be color coded if the "facets" gem is installed.
#
class Journal

  attr_reader :logger, :colorize

  # Create a new journal
  #
  def initialize
    @logger = ::Logging::Logger[self]
    @colorize = defined?(::ANSICode) and ENV.has_key?('TERM')
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
    type = ::ANSICode.send(color, type) unless color.nil?
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

end  # class Journal
end  # module Webby

# EOF
