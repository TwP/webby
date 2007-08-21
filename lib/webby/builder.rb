# $Id$

require 'find'
require 'fileutils'
require 'erb'

module Webby

# The Builder class performs the work of scanning the content folder,
# creating Resource objects, and converting / copying the contents to the
# output folder as needed.
#
class Builder

  class << self

    # call-seq:
    #    Builder.run( :rebuild => false )
    #
    # Create a new instance of the Builder class and invoke the run method.
    # If the <code>:rebuild</code> option is given as +true+, then all pages
    # will be recreated / copied.
    #
    def run( opts = {} )
      self.new.run opts
    end

    # call-seq:
    #    Builder.create( page, :from => template )
    #
    # This mehod is used to create a new _page_ in the content folder based
    # on the specified template. _page_ is the relative path to the new page
    # from the <code>content/</code> folder. The _template_ is the name of
    # the template to use from the <code>templates/</code> folder.
    #
    def create( page, opts = {} )
      tmpl = opts[:from]
      raise Error, "template not given" unless tmpl
      raise Error, "#{page} already exists" if test ?e, page

      puts "creating #{page}"
      FileUtils.mkdir_p File.dirname(page)
      str = ERB.new(::File.read(tmpl), nil, '-').result
      ::File.open(page, 'w') {|fd| fd.write str}

      return nil
    end
  end  # class << self

  # call-seq:
  #    run( :rebuild => false )
  #
  # Runs the Webby builder by loading in the layout files from the
  # <code>layouts/</code> folder and the content from the
  # <code>contents/</code> folder. Content is analyzed, and those that need
  # to be copied or compiled (filtered using ERB, Texttile, Markdown, etc.)
  # are handled. The results are placed in the <code>output/</code> folder.
  #
  # If the <code>:rebuild</code> flag is set to +true+, then all content is
  # copied and/or compiled to the output folder.
  #
  # A content file can mark itself as dirty by setting the +dirty+ flag to
  # +true+ in the meta-data of the file. This will cause the contenet to
  # always be compiled when the builder is run. Conversely, setting the
  # dirty flag to +false+ will cause the content to never be compiled or
  # copied to the output folder.
  #
  # A content file needs to be built if the age of the file is less then the
  # age of the output product -- i.e. the content file has been modified
  # more recently than the output file.
  #
  def run( opts = {} )
    Resource.reset

    unless test(?d, output_dir)
      puts "creating #{output_dir}"
      FileUtils.mkdir output_dir
    end

    load_layouts
    load_content

    Resource.pages.each do |page|
      next unless page.dirty? or opts[:rebuild]

      puts "creating #{page.destination}"

      # make sure the directory exists
      FileUtils.mkdir_p ::File.dirname(page.destination)

      # copy the resource to the output directory if it is static
      if page.is_static?
        FileUtils.cp page.path, page.destination

      # otherwise, layout the resource and write the results to
      # the output directory
      else
        ::File.open(page.destination, 'w') do |fd|
          fd.write Renderer.new(page).layout_page
        end
      end
    end

    # touch the output directory so we know when the
    # website was last generated
    FileUtils.touch output_dir

    return nil
  end


  private

  # Scan the <code>layouts/</code> folder and create a new Resource object
  # for each file found there.
  #
  def load_layouts
    excl = Regexp.new exclude.join('|')

    ::Find.find(layout_dir) do |path|
      next unless test ?f, path
      next if path =~ excl
      Resource.new path
    end

    layouts = Resource.layouts

    # look for loops in the layout references -- i.e. a layout
    # eventually refers back to itself
    layouts.each do |lyt|
      stack = []
      while lyt
        if stack.include? lyt.filename
          stack << lyt.filename
          raise Error,
                "loop detected in layout references: #{stack.join(' > ')}"
        end
        stack << lyt.filename
        lyt = layouts.find_by_name lyt.layout
      end  # while
    end  # each
  end

  # Scan the <code>content/</code> folder and create a new Resource object
  # for each file found there.
  #
  def load_content
    excl = Regexp.new exclude.join('|')
    Find.find(content_dir) do |path|
      next unless test ?f, path
      next if path =~ excl
      Resource.new path, ::Webby.page_defaults
    end
  end

  %w(output_dir layout_dir content_dir exclude).each do |key|
    self.class_eval <<-CODE
      def #{key}( ) ::Webby.config['#{key}'] end
    CODE
  end

end  # class Builder
end  # module Webby

# EOF
