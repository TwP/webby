
namespace :create do

  FileList["#{Webby.site.template_dir}/*"].each do |template|
    name = template.pathmap '%n'
    next if name =~ %r/^blog_/  # skip blog entries

    # if the file is a partial template
    if name =~ %r/^_(.*)/
      name = $1
      desc "Create a new #{name}"
      task name do |t|
        Webby::Builder.create(:partial, :from => template, :task => t)
      end

    # otherwise it's a normal file
    else
      desc "Create a new #{name}"
      task name do |t|
        Webby::Builder.create(:page, :from => template, :task => t)
      end
    end
  end  # each

end  # namespace :create

# EOF
