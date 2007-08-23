# $Id$

begin
  require 'rake'
  require 'rake/tasklib'
rescue LoadError
  require 'rubygems'
  raise unless gem 'rake'
  retry
end

module Rake

# The WebbyTask defines several rake tasks for working with Webby based
# websites:
#
# [:build]  Build the site by compiling only those resources in the content
#           folder that have been modifed recently. If the a content file
#           has a modification time more recent then its corresponding
#           output file, then it will be built by this task.
#
# [:rebuild]  Rebuild the entire site from the content folder and store the
#             results in the output folder.
#
# [:autobuild]  Monitors the content and layout directories for modified
#               resources and compiles those files as needed. This task
#               returns only when the user hits Ctrl-C.
#
# [:create:page]  Create a new page in the content folder based on the
#                 template 'page' found in the templates folder. One task
#                 will be created for each file found in the templates
#                 folder.
#
class WebbyTask < TaskLib

  # Location of the generated website
  attr_accessor :output_dir

  # Location of the webiste source material
  attr_accessor :content_dir

  # Location of the layout files for generated pages
  attr_accessor :layout_dir

  # Location of the page templates
  attr_accessor :template_dir

  # Array of patterns used to exclude files
  attr_accessor :exclude

  # Global page attributes (default is {})
  attr_reader :page_defaults

  # Merge the given _hash_ with the page defaults hash
  def page_defaults=( hash )
    @page_defaults.merge! hash
  end

  # call-seq:
  #    WebbyTask.new {|self| block}
  #
  # Create the tasks used by Webby to build a website and to create new
  # pages in the website.
  #
  def initialize
    @output_dir = 'output'
    @content_dir = 'content'
    @layout_dir = 'layouts'
    @template_dir = 'templates'
    @exclude = %w(tmp$ bak$ ~$ CVS \.svn)
    @page_defaults = {
      'extension' => 'html',
      'layout'    => 'default'
    }

    yield self if block_given?

    ::Webby.config.merge!({
      'output_dir' => @output_dir,
      'content_dir' => @content_dir,
      'layout_dir' => @layout_dir,
      'template_dir' => @template_dir,
      'exclude' => @exclude
    })
    ::Webby.page_defaults.merge! @page_defaults

    # load any user defined libraries
    glob = File.join(FileUtils.pwd, 'lib', '**', '*.rb')
    Dir.glob(glob).sort.each {|fn| require fn}

    # create the Webby rake tasks
    define_build_tasks
    namespace(:create) {define_create_tasks}
  end

  # Defines the :build and :rebuild tasks
  #
  def define_build_tasks
    desc "build the website"
    task :build do |t|
      ::Webby::Builder.run
    end

    desc "rebuild the website"
    task :rebuild do |t|
      ::Webby::Builder.run :rebuild => true
    end

    desc "continuously build the website"
    task :autobuild do |t|
      ::Webby::AutoBuilder.run
    end
  end

  # Scans the templates directory for any files, and creats a corresponding
  # task for creating a new page based on that template.
  #
  def define_create_tasks
    FileList["#{@template_dir}/*"].each do |template|
      name = template.pathmap '%n'

      desc "create a new #{name} page"
      task name do |t|
        raise "Usage:  rake #{t.name} path" unless ARGV.length == 2

        page = t.application.top_level_tasks.pop
        page = File.join(@content_dir, page)
        page << '.txt' if File.extname(page).empty?

        ::Webby::Builder.create page, :from => template
      end  # task
    end  # each
  end

end  # class WebbyTask
end  # module Rake

# EOF
