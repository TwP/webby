require 'optparse'
require 'rake'

module Webby

# The Webby::Main class contains all the functionality needed by the +webby+
# command line application.
#
class Main

  # Create a new instance of Main, and run the +webby+ application given the
  # command line _args_.
  #
  def self.run( args )
    self.new.run args
  end

  # Create a new Main webby object for building websites.
  #
  def initialize
    @stdout = $stdout
  end

  def run( args )
    case args[0]
    when 'gen'
      args.shift
      gen = Generator.new
      gen.run args
    when nil              then help
    when %r/^(-h|--help)/ then help
    when '--version'      then version
    else rake(args) end
  end

  def rake( args )
    # TODO: fill in the rake stuff
    @stdout.puts 'rake'
  end

  def version
    @stdout.puts "Webby #{::Webby::VERSION}"
  end

  def help
    # TODO: get a good help message going
    #       maybe use the option parser just for the help message
    @stdout.puts "Usage: webby [options] target [target args]"
    @stdout.puts
  end

end  # class Main
end  # module Webby

# EOF
