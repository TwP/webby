
namespace :website do

  desc 'Build the Webby website'
  task :build do
    begin
      olddir = pwd
      chdir 'examples/webby'
      sh 'webby rebuild BASE="http://webby.rubyforge.org"'
      cp_r 'output/.', olddir + '/doc'
    ensure
      chdir olddir
    end
  end

  desc 'Remove the Webby website'
  task :clobber do
    rm_r 'doc' rescue nil
  end

  desc 'Publish the website to RubyForge'
  task :release => %w(website:clobber doc:rdoc website:build) do
    config = YAML.load(
        File.read(File.expand_path('~/.rubyforge/user-config.yml'))
    )

    host = "#{config['username']}@rubyforge.org"
    remote_dir = "/var/www/gforge-projects/#{Bones.config.rubyforge.name}/"

    sh "rsync --delete -rulptzCF doc/ #{host}:#{remote_dir}"
  end

end  # namespace :website

task :clobber => 'website:clobber'

# EOF
