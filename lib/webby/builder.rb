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

      Logging::Logger[self].info "creating #{page}"
      FileUtils.mkdir_p ::File.dirname(page)
      str = ERB.new(::File.read(tmpl), nil, '-').result
      ::File.open(page, 'w') {|fd| fd.write str}

      return nil
    end
  end  # class << self

  # call-seq:
  #    Builder.new
  #
  # Creates a new Builder object for creating pages from the content and
  # layout directories.
  #
  def initialize
    @log = Logging::Logger[self]
  end

  # call-seq:
  #    run( :rebuild => false, :load_files => true )
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
    opts[:load_files] = true unless opts.has_key?(:load_files)

    unless test(?d, output_dir)
      @log.info "creating #{output_dir}"
      FileUtils.mkdir output_dir
    end

    load_files if opts[:load_files]

    Resources.pages.each do |page|
      next unless page.dirty? or opts[:rebuild]

      @log.info "creating #{page.destination}"

      # make sure the directory exists
      FileUtils.mkdir_p ::File.dirname(page.destination)

      # copy the resource to the output directory if it is static
      if page.instance_of? Resources::Static
        FileUtils.cp page.path, page.destination
        FileUtils.chmod 0644, page.destination

      # otherwise, layout the resource and write the results to
      # the output directory
      else Renderer.write(page) end
    end

    # touch the cairn so we know when the website was last generated
    FileUtils.touch ::Webby.cairn

    nil
  end


  private

  # Scan the <code>layouts/</code> folder and the <code>content/</code>
  # folder and create a new Resource object for each file found there.
  #
  def load_files
    ::Find.find(layout_dir, content_dir) do |path|
      next unless test ?f, path
      next if path =~ ::Webby.exclude
      Resources.new path
    end
  end

  %w(output_dir layout_dir content_dir).each do |key|
    self.class_eval <<-CODE
      def #{key}( ) ::Webby.site.#{key} end
    CODE
  end

end  # class Builder
end  # module Webby

# EOF
