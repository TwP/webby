# $Id$

require 'rake/gempackagetask'
require 'rubyforge' if PROJ.rubyforge_name && HAVE_RUBYFORGE

namespace :gem do

  spec = Gem::Specification.new do |s|
    s.name = PROJ.name
    s.version = PROJ.version
    s.summary = PROJ.summary
    s.authors = Array(PROJ.authors)
    s.email = PROJ.email
    s.homepage = Array(PROJ.url).first
    s.rubyforge_project = PROJ.rubyforge_name

    s.description = PROJ.description

    PROJ.dependencies.each do |dep|
      s.add_dependency(*dep)
    end
    if PROJ.rubyforge_name && HAVE_RUBYFORGE
      s.add_dependency('rubyforge', ">= #{::RubyForge::VERSION}")
    end
    s.add_dependency('rake', ">= #{RAKEVERSION}")

    s.files = PROJ.files
    s.executables = PROJ.executables.map {|fn| File.basename(fn)}
    s.extensions = PROJ.files.grep %r/extconf\.rb$/

    s.bindir = 'bin'
    dirs = Dir['{lib,ext}']
    s.require_paths = dirs unless dirs.empty?

    rdoc_files = PROJ.files.grep %r/txt$/
    rdoc_files.delete 'Manifest.txt'
    s.rdoc_options = PROJ.rdoc_opts + ['--main', PROJ.rdoc_main]
    s.extra_rdoc_files = rdoc_files
    s.has_rdoc = true

    if test ?f, PROJ.test_file
      s.test_file = PROJ.test_file
    else
      s.test_files = PROJ.tests.to_a
    end

    # Do any extra stuff the user wants
#   spec_extras.each do |msg, val|
#     case val
#     when Proc
#       val.call(s.send(msg))
#     else
#       s.send "#{msg}=", val
#     end
#   end
  end

  desc 'Show information about the gem'
  task :debug do
    puts spec.to_ruby
  end

  Rake::GemPackageTask.new(spec) do |pkg|
    pkg.need_tar = PROJ.need_tar
    pkg.need_zip = PROJ.need_zip
  end

  desc 'Install the gem'
  task :install => [:clobber, :package] do
    sh "#{SUDO} #{GEM} install pkg/#{spec.file_name}"
  end

  desc 'Uninstall the gem'
  task :uninstall do
    sh "#{SUDO} #{GEM} uninstall -v '#{PROJ.version}' #{PROJ.name}"
  end

  if PROJ.rubyforge_name && HAVE_RUBYFORGE
    desc 'Package and upload to RubyForge'
    task :release => [:clobber, :package] do |t|
      v = ENV['VERSION'] or abort 'Must supply VERSION=x.y.z'
      abort "Versions don't match #{v} vs #{PROJ.version}" if v != PROJ.version
      pkg = "pkg/#{spec.full_name}"

      if $DEBUG then
        puts "release_id = rf.add_release #{PROJ.rubyforge_name.inspect}, #{PROJ.name.inspect}, #{PROJ.version.inspect}, \"#{pkg}.tgz\""
        puts "rf.add_file #{PROJ.rubyforge_name.inspect}, #{PROJ.name.inspect}, release_id, \"#{pkg}.gem\""
      end

      rf = RubyForge.new
      puts 'Logging in'
      rf.login

      c = rf.userconfig
      c['release_notes'] = PROJ.description if PROJ.description
      c['release_changes'] = PROJ.changes if PROJ.changes
      c['preformatted'] = true

      files = [(PROJ.need_tar ? "#{pkg}.tgz" : nil),
               (PROJ.need_zip ? "#{pkg}.zip" : nil),
               "#{pkg}.gem"].compact

      puts "Releasing #{PROJ.name} v. #{PROJ.version}"
      rf.add_release PROJ.rubyforge_name, PROJ.name, PROJ.version, *files
    end
  end

end  # namespace :gem

task :clobber => 'gem:clobber_package'

# EOF
