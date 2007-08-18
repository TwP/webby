# $Id$

begin
  require 'webby'
rescue LoadError
  path = File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib'))
  raise if $:.include? path
  $: << path
  retry
end

# EOF
