# Equivalent to a header guard in C/C++
# Used to prevent the spec helper from being loaded more than once
unless defined? WEBBY_SPEC_HELPER
WEBBY_SPEC_HELPER = true

require 'rubygems'
require 'fileutils'

require File.expand_path(
    File.join(File.dirname(__FILE__), %w[.. lib webby]))

Spec::Runner.configure do |config|
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

end  # unless defined?

# EOF
