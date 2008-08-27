# Equivalent to a header guard in C/C++
# Used to prevent the spec helper from being loaded more than once
unless defined? WEBBY_SPEC_HELPER
WEBBY_SPEC_HELPER = true

require 'rubygems'
require 'fileutils'
require 'stringio'

require File.expand_path(
    File.join(File.dirname(__FILE__), %w[.. lib webby]))

Spec::Runner.configure do |config|
  config.before :all do
    @pwd = Dir.pwd
    Dir.chdir Webby.datapath
    FileUtils.mkdir_p Webby.datapath(::Webby.site.output_dir)
  end

  config.after :all do
    FileUtils.rm_rf(Webby.datapath(::Webby.cairn))
    FileUtils.rm_rf(Dir.glob(Webby.datapath %w[output *]))
    Dir.chdir @pwd
  end

  # == Mock Framework
  #
  # RSpec uses it's own mocking framework by default. If you prefer to
  # use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr
end

module Webby
  DATAPATH = ::Webby.path(%w[spec data])
  def self.datapath( *args )
    args.empty? ? DATAPATH : ::File.join(DATAPATH, args.flatten)
  end
end

$webby_log_output = StringIO.new

logger = Logging::Logger['Webby']
logger.clear_appenders
logger.add_appenders(Logging::Appenders::IO.new('stringio', $webby_log_output))

end  # unless defined?

# EOF
