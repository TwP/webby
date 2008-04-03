
namespace :create do

  FileList["#{Webby.site.template_dir}/*"].each do |template|
    next unless test(?f, template)
    name = template.pathmap '%n'

    # if the file is a partial template
    name = $1 if name =~ %r/^_(.*)/

    desc "Create a new #{name}"
    task name do |t|
      page, title, dir = Webby::Builder.new_page_info(t)
      page = Webby::Builder.create(page, :from => template,
                 :locals => {:title => title, :directory => dir})
      exec(::Webby.editor, page) unless ::Webby.editor.nil?
    end
  end  # each

end  # namespace :create

# EOF
