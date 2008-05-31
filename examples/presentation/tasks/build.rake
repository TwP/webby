
task :configure_basepath do
  Webby.site.base = ENV['BASE'] if ENV.has_key?('BASE')
end

desc "Build the website"
task :build => :configure_basepath do |t|
  Webby::Builder.run
end

desc "Rebuild the website"
task :rebuild => :configure_basepath do |t|
  Webby::Builder.run :rebuild => true
end

desc "Continuously build the website"
task :autobuild => :configure_basepath do |t|
  Webby::AutoBuilder.run
end

desc "Delete the website"
task :clobber do |t|
  rm_rf Webby.site.output_dir
  mkdir Webby.site.output_dir
end

# EOF
