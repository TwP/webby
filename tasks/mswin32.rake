
require 'find'

namespace 'gem:mswin32' do

  win32_spec = Bones.config.gem._spec.dup
  win32_spec.platform = 'x86-mswin32'
  win32_spec.files = Bones.config.gem.files

  pkg = Bones::GemPackageTask.new(win32_spec)
  class << pkg
    def package_dir_path() "#{package_dir}/#{package_name}-x86-mswin32"; end
  end
  pkg.define

  file "#{pkg.package_dir_path}/#{pkg.gem_file}" => :unix2dos

  task :unix2dos do
    reject = %w[.gif .jpg .jpeg]
    Find.find(File.join(pkg.package_dir_path, 'examples')) do |fn|
      next unless test(?f, fn)
      next if reject.include?(File.extname(fn))
      sh %{unix2dos #{fn}}
    end
  end
end  # namespace 'gem:mswin32'


task :gem => 'gem:mswin32:package'
task :clobber => 'gem:mswin32:clobber_package'

# remove_desc_for_task(%w[
#   gem:mswin32:clobber_package
#   gem:mswin32:package
#   gem:mswin32:repackage
# ])

# EOF
