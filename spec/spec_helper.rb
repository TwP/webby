# Equivalent to a header guard in C/C++
# Used to prevent the spec helper from being loaded more than once
unless defined? WEBBY_SPEC_HELPER
WEBBY_SPEC_HELPER = true

begin
  require 'fake_web'
  $test_externals = true
rescue LoadError
  retry if require 'rubygems'
  $test_externals = false
end

require 'fileutils'
require 'spec/logging_helper'

dir = File.expand_path(File.dirname(__FILE__))
require File.join(dir, %w[.. lib webby])
Dir.glob(File.join(dir, %w[helpers *_helper.rb])).each {|fn| require fn}

Spec::Runner.configure do |config|
  include Spec::LoggingHelper
  include WebbyHelper

  # == Mock Framework
  #
  # RSpec uses it's own mocking framework by default. If you prefer to
  # use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr

  config.capture_log_messages :from => 'Webby'
  config.webby_site_setup
end

end  # unless defined?

# EOF
