
namespace :blog do

  FileList["#{Webby.site.template_dir}/blog_*"].each do |template|
    m = %r/^blog_(.*)$/.match(template.pathmap('%n'))
    name = m[1]
    next if name =~ %r/^(month|year)$/  # skip month/year blog entries

    desc "Create a new blog #{name}"
    task name do |t|
      Webby::Builder.create(:blog, :from => template, :task => t)
    end
  end  # each

end  # namespace :blog

# EOF
