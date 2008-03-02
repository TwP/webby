# $Id$

require 'rake'
require 'rake/tasklib'

module Rake  # :nodoc:

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

  # call-seq:
  #    WebbyTask.new {|self| block}
  #
  # Create the tasks used by Webby to build a website and to create new
  # pages in the website.
  #
  def initialize
    yield self if block_given?

    # load any user defined libraries
    glob = ::File.join(FileUtils.pwd, 'lib', '**', '*.rb')
    Dir.glob(glob).sort.each {|fn| require fn}

    # create the Webby rake tasks
    define_build_tasks
    namespace(:create) {define_create_tasks}
  end

  # Defines the :build and :rebuild tasks
  #
  def define_build_tasks
    task :configure_basepath do
      ::Webby.site.base = ENV['BASE'] if ENV.has_key?('BASE')
    end

    desc "Build the website"
    task :build => :configure_basepath do |t|
      ::Webby::Builder.run
    end

    desc "Rebuild the website"
    task :rebuild => :configure_basepath do |t|
      ::Webby::Builder.run :rebuild => true
    end

    desc "Continuously build the website"
    task :autobuild => :configure_basepath do |t|
      ::Webby::AutoBuilder.run
    end

    desc "Delete the website"
    task :clobber do |t|
      rm_rf ::Webby.site.output_dir
      mkdir ::Webby.site.output_dir
    end
  end

  # TODO: modify creation task to handle folders of pages/partials

  # Scans the templates directory for any files, and creats a corresponding
  # task for creating a new page based on that template.
  #
  def define_create_tasks
    FileList["#{::Webby.site.template_dir}/*"].each do |template|
      name = template.pathmap '%n'

      # if the file is a partial template
      if name =~ %r/^_(.*)/
        name = $1
        desc "Create a new #{name}"
        task name do |t|
          raise "Usage:  rake #{t.name} path" unless ARGV.length == 2

          page = t.application.top_level_tasks.pop
          name = '_' + ::Webby::Resources::File.basename(page)
          ext  = ::Webby::Resources::File.extname(page)
          dir  = ::File.dirname(page)
          dir  = '' if dir == '.'

          page = ::File.join(::Webby.site.content_dir, dir, name)
          page << '.' << (ext.empty? ? 'txt' : ext)

          ::Webby::Builder.create page, :from => template
        end

      # otherwise it's a normal file
      else
        desc "Create a new #{name}"
        task name do |t|
          raise "Usage:  rake #{t.name} path" unless ARGV.length == 2

          page = t.application.top_level_tasks.pop
          name = ::Webby::Resources::File.basename(page)
          ext  = ::Webby::Resources::File.extname(page)
          dir  = ::File.dirname(page)
          dir  = '' if dir == '.'

          if ::Webby.site.create_mode == 'directory'
            page = ::File.join(::Webby.site.content_dir, dir, name, 'index')
            page << '.' << (ext.empty? ? 'txt' : ext)
          else
            page = ::File.join(::Webby.site.content_dir, page)
            page << '.txt' if ext.empty?
          end

          ::Webby::Builder.create page, :from => template
        end  # task
      end
    end  # each
  end

end  # class WebbyTask
end  # module Rake

# EOF
