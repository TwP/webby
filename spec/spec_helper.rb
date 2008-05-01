# Equivalent to a header guard in C/C++
# Used to prevent the spec helper from being loaded more than once
unless defined? WEBBY_SPEC_HELPER
WEBBY_SPEC_HELPER = true

require 'rubygems'
require 'fileutils'

require File.expand_path(
    File.join(File.dirname(__FILE__), %w[.. lib webby]))

end  # unless defined?

# EOF
