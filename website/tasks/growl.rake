
desc 'send log events to Growl (Mac OS X only)'
task :growl do
  Logging::Logger['Webby'].add(Logging::Appenders::Growl.new(
    "Webby",
    :layout => Logging::Layouts::Pattern.new(:pattern => "%5l - Webby\n%m")
  ))
end

# EOF
