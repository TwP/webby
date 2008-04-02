
namespace :blog do

  FileList["#{Webby.site.template_dir}/blog/*"].each do |template|
    next unless test(?f, template)
    name = template.pathmap('%n')
    next if name =~ %r/^(month|year)$/  # skip month/year blog entries

    desc "Create a new blog #{name}"
    task name => [:create_year_index, :create_month_index] do |t|
      page, title, dir = Webby::Builder.new_page_info(t)

      # if no directory was given use the default blog directory (underneath
      # the content directory)
      dir = Webby.site.blog_dir if dir.empty?

      page = File.join(dir, Time.now.strftime('%Y/%m/%d'), File.basename(page))
      page = Webby::Builder.create(page,
                 :from => template, :locals => {:title => title})
      exec(::Webby.editor, page) unless ::Webby.editor.nil?
    end
  end  # each

  task :create_year_index do |t|
    # parse out information about the page to create
    _, _, dir = Webby::Builder.new_page_info(t)
    year = Time.now.strftime '%Y'

    # if no directory was given use the default blog directory (underneath
    # the content directory)
    dir = Webby.site.blog_dir if dir.empty?

    # determine the filename and template name
    fn = File.join(dir, year, 'index.txt')
    tmpl = Dir.glob(File.join(Webby.site.template_dir, 'blog/year.*')).first.to_s

    if test(?f, tmpl) and not test(?f, File.join(Webby.site.content_dir, fn))
      Webby::Builder.create(fn, :from => tmpl, :locals => {:title => year})
    end
  end

  task :create_month_index do |t|
    # parse out information about the page to create
    _, _, dir = Webby::Builder.new_page_info(t)
    now = Time.now

    # if no directory was given use the default blog directory (underneath
    # the content directory)
    dir = Webby.site.blog_dir if dir.empty?

    # determine the filename and template name
    fn = File.join(dir, now.strftime('%Y/%m'), 'index.txt')
    tmpl = Dir.glob(File.join(Webby.site.template_dir, 'blog/month.*')).first.to_s

    if test(?f, tmpl) and not test(?f, File.join(Webby.site.content_dir, fn))
      Webby::Builder.create(fn,
          :from => tmpl, :locals => {:title => now.strftime('%B %Y')})
    end
  end

end  # namespace :blog

# EOF
