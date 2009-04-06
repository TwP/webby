Loquacious.configuration_for(:webby) {
  desc "The default directory where new blog posts will be created."
  blog_dir 'blog'
}

namespace :blog do

  # iterate over all the files in the "templates/blog" folder and create a
  # rake task corresponding to each file found
  FileList["#{Webby.site.template_dir}/blog/*"].each do |template|
    next unless test(?f, template)
    name = template.pathmap('%n')
    next if name =~ %r/^(month|year)$/  # skip month/year blog entries

    desc "Create a new blog #{name}"
    task name => [:create_year_index, :create_month_index] do |t|
      page, title, dir = Webby::Builder.new_page_info

      # if no directory was given use the default blog directory (underneath
      # the content directory)
      dir = Webby.site.blog_dir if dir.empty?
      dir = File.join(dir, Time.now.strftime('%Y/%m/%d'))

      page = File.join(dir, File.basename(page))
      page = Webby::Builder.create(page, :from => template,
                 :locals => {:title => title, :directory => dir})
      Webby.exec_editor(page)
    end
  end  # each

  # this task is used to create the year index file (blog/2008/index.txt)
  task :create_year_index do |t|
    # parse out information about the page to create
    _, _, dir = Webby::Builder.new_page_info
    year = Time.now.strftime '%Y'

    # if no directory was given use the default blog directory (underneath
    # the content directory)
    dir = Webby.site.blog_dir if dir.empty?
    dir = File.join(dir, year)

    # determine the filename and template name
    fn = File.join(dir, 'index.txt')
    tmpl = Dir.glob(File.join(Webby.site.template_dir, 'blog/year.*')).first.to_s

    if test(?f, tmpl) and not test(?f, File.join(Webby.site.content_dir, fn))
      Webby::Builder.create(fn, :from => tmpl,
          :locals => {:title => year, :directory => dir})
    end
  end

  # this task is used to create the month index file (blog/2008/04/index.txt)
  task :create_month_index do |t|
    # parse out information about the page to create
    _, _, dir = Webby::Builder.new_page_info
    now = Time.now
    month = now.strftime '%m'

    # if no directory was given use the default blog directory (underneath
    # the content directory)
    dir = Webby.site.blog_dir if dir.empty?
    dir = File.join(dir, now.strftime('%Y/%m'))

    # determine the filename and template name
    fn = File.join(dir, 'index.txt')
    tmpl = Dir.glob(File.join(Webby.site.template_dir, 'blog/month.*')).first.to_s

    if test(?f, tmpl) and not test(?f, File.join(Webby.site.content_dir, fn))
      Webby::Builder.create(fn, :from => tmpl,
          :locals => {:title => month, :directory => dir})
    end
  end

end  # namespace :blog

# EOF
