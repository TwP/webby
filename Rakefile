# $Id$

load 'tasks/setup.rb'

ensure_in_path 'lib'
require 'webby'

task :default => 'spec:run'

PROJ.name = 'webby'
PROJ.summary = 'static website creation and management'
PROJ.authors = 'Tim Pease'
PROJ.email = 'tim.pease@gmail.com'
PROJ.url = 'http://webby.rubyforge.org/'
PROJ.description = paragraphs_of('README.txt', 3).join("\n\n")
PROJ.rubyforge_name = 'webby'
PROJ.rdoc_dir = 'doc/rdoc'
PROJ.rdoc_remote_dir = 'rdoc'
PROJ.version = Webby::VERSION
PROJ.release_name = 'Wandering Wookie'

PROJ.exclude << %w(^examples/[^/]+/output ^tasks/archive ^tags$)
PROJ.rdoc_exclude << %w(^data ^examples)

PROJ.svn = true
PROJ.spec_opts << '--color'

PROJ.ann_email[:to] << 'webby-forum@googlegroups.com'
PROJ.ann_email[:server] = 'smtp.gmail.com'
PROJ.ann_email[:port] = 587

PROJ.ann_text = <<-ANN
== FUN FACT

A Boeing 747's wingspan is longer than the Wright brothers first flight.

== POST SCRIPT

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
