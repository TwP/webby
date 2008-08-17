
module Webby::Apps

  class << self
    def author() 'Tim Pease'; end
  end

end  # module Webby::Apps

Webby.require_all_libs_relative_to(__FILE__)

# EOF
