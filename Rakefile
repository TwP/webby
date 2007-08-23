# $Id$

require 'rubygems'
require 'rake'
require 'spec'
require 'webby'
load './tasks/setup.rb'

task :default => 'spec:run'

PROJ.name = 'webby'
PROJ.summary = 'static website creation and management'
PROJ.authors = 'Tim Pease'
PROJ.email = 'tim.pease@gmail.com'
PROJ.url = 'http://webby.rubyforge.org/'
PROJ.description = paragraphs_of('README.txt', 3).join("\n\n")
PROJ.changes = paragraphs_of('History.txt', 0..1).join("\n\n")
PROJ.rubyforge_name = 'webby'
PROJ.rdoc_remote_dir = 'rdoc'
PROJ.version = Webby::VERSION

PROJ.exclude << '^(\.\/|\/)?site'
PROJ.rdoc_exclude << '^(\.\/|\/)?data'

PROJ.spec_opts << '--color'

PROJ.dependencies << ['rspec', ">= #{Spec::VERSION::STRING}"]
PROJ.dependencies << ['directory_watcher', ">= #{DirectoryWatcher::VERSION}"]

# EOF
