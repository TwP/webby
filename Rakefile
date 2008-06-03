# $Id$

load 'tasks/setup.rb'

ensure_in_path 'lib'
require 'webby'

task :default => 'spec:specdoc'

PROJ.name = 'webby'
PROJ.summary = 'static website creation and management'
PROJ.authors = 'Tim Pease'
PROJ.email = 'tim.pease@gmail.com'
PROJ.url = 'http://webby.rubyforge.org/'
PROJ.description = paragraphs_of('README.txt', 3).join("\n\n")
PROJ.rubyforge.name = 'webby'
PROJ.version = Webby::VERSION
PROJ.release_name = 'Forgetful Foobar'

PROJ.ruby_opts = %w[-W0]
PROJ.exclude << %w(^examples/[^/]+/output ^tasks/archive ^tags$)

PROJ.rdoc.dir = 'doc/rdoc'
PROJ.rdoc.remote_dir = 'rdoc'
PROJ.rdoc.exclude << %w(^data ^examples)

PROJ.svn.path = ''
PROJ.spec.opts << '--color'

PROJ.ann.email[:to] << 'webby-forum@googlegroups.com'
PROJ.ann.email[:server] = 'smtp.gmail.com'
PROJ.ann.email[:port] = 587

PROJ.ann.text = <<-ANN
== FUN FACT

TODO: add a new fun fact before next release

== POST SCRIPT

Visit the Webby forum to chat with other Webby-Heads:
http://groups.google.com/group/webby-forum

Blessings,
TwP
ANN

depend_on 'directory_watcher'
depend_on 'heel'
depend_on 'hpricot'
depend_on 'logging'
depend_on 'rake'
depend_on 'rspec'

# EOF
