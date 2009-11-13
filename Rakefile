
begin
  require 'bones'
rescue LoadError
  abort '### please install the "bones" gem ###'
end

ensure_in_path 'lib'
require 'webby'

task :default => 'spec:specdoc'

Bones {
  name 'webby'
  summary 'Awesome static website creation and management!'
  authors 'Tim Pease'
  email 'tim.pease@gmail.com'
  url 'http://webby.rubyforge.org/'
  version Webby::VERSION
  readme_file 'README.rdoc'
  ignore_file '.gitignore'
  rubyforge.name 'webby'

  ruby_opts %w[-W0]
  exclude << %w(^webby.gemspec$)

  rdoc.dir 'doc/rdoc'
  rdoc.remote_dir 'rdoc'
  rdoc.exclude << %w(^examples)
  rdoc.include << readme_file

  spec.opts << '--color'

  use_gmail
  ann.email.to << 'webby-forum@googlegroups.com'
  ann.text = <<-ANN
== POST SCRIPT

Visit the Webby forum to chat with other Webby-Heads:
http://groups.google.com/group/webby-forum

Blessings,
TwP
ANN

  depend_on 'directory_watcher'
  depend_on 'hpricot'
  depend_on 'launchy'
  depend_on 'logging'
  depend_on 'loquacious'
  depend_on 'rake'

  depend_on 'rspec', :development => true
  depend_on 'bones-git', :development => true
  depend_on 'bones-extras', :development => true
}

