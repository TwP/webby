
begin
  require 'webby'
rescue LoadError
  require 'rubygems'
  require 'webby'
end

SITE = Webby.site

# Load the other rake files in the tasks folder
Dir.glob(::File.join(%w[tasks *.rake])).sort.each {|fn| import fn}

# Load all the ruby files in the lib folder
Dir.glob(::File.join(%w[lib ** *.rb])).sort.each {|fn| require fn}

# EOF
