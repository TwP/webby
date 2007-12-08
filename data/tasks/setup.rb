# Load webby from vendor/webby if available
$:.unshift File.dirname(__FILE__) + '/../vendor/webby/lib'
require 'webby'

# Load vendor/filters/*.rb
Webby.require_all_libs_relative_to File.dirname(__FILE__) + '/../vendor/filters'

# Note: Override SITE defaults in Rakefile
SITE = Webby.site

# Load up the other rake tasks
FileList['tasks/*.rake'].each {|task| import task}

# Conditional dependencies
%w(heel).each do |lib|
  Object.instance_eval {const_set "HAVE_#{lib.upcase}", try_require(lib)}
end

# EOF