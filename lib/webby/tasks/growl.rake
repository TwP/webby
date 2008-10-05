
unless WINDOWS

task :growl do
  growl = Logging::Appenders::Growl.new('growl',
    :layout => Logging::Layouts::Pattern.new(:pattern => "%5l - Webby\000%m"),
    :coalesce => true,
    :separator => "\000"
  )
  Logging::Logger['Webby'].add_appenders(growl)
  Logging::Logger['Webby::Journal'].add_appenders(growl)
end

end  # unless WINDOWS

# EOF
