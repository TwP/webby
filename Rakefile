
begin
  require 'bones'
  Bones.setup
rescue LoadError
  begin
    load 'tasks/setup.rb'
  rescue LoadError
    raise RuntimeError, '### please install the "bones" gem ###'
  end
end

ensure_in_path 'lib'
require 'webby'

task :default => 'spec:specdoc'

PROJ.name = 'webby'
PROJ.summary = 'Awesome static website creation and management!'
PROJ.authors = 'Tim Pease'
PROJ.email = 'tim.pease@gmail.com'
PROJ.url = 'http://webby.rubyforge.org/'
PROJ.rubyforge.name = 'webby'
PROJ.version = Webby::VERSION
PROJ.release_name = 'Supertaculous'
PROJ.readme_file = 'README.rdoc'
PROJ.ignore_file = '.gitignore'

PROJ.ruby_opts = %w[-W0]
PROJ.exclude << %w(^webby.gemspec$)

PROJ.rdoc.dir = 'doc/rdoc'
PROJ.rdoc.remote_dir = 'rdoc'
PROJ.rdoc.exclude << %w(^examples)
PROJ.rdoc.include << PROJ.readme_file

PROJ.spec.opts << '--color'

PROJ.ann.email[:to] << 'webby-forum@googlegroups.com'
PROJ.ann.email[:server] = 'smtp.gmail.com'
PROJ.ann.email[:port] = 587
PROJ.ann.email[:from] = 'Tim Pease'

PROJ.ann.text = <<-ANN
== POST SCRIPT

Visit the Webby forum to chat with other Webby-Heads:
http://groups.google.com/group/webby-forum

Blessings,
TwP
ANN

depend_on 'directory_watcher'
depend_on 'hpricot', '>= 0.6.0'
depend_on 'launchy'
depend_on 'logging'
depend_on 'loquacious'
depend_on 'rake'
depend_on 'rspec'

# EOF
