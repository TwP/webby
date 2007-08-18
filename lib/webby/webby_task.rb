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

    define_build_tasks
    namespace(:create) {define_create_tasks}
  end


  private

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

        ::Webby::Builder.create page, :from => template
      end  # task
    end  # each
  end

end  # class WebbyTask
end  # module Rake

# EOF
