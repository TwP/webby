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
    #    Builder.create( page, :from => template, :locals => {} )
    #
    # This mehod is used to create a new _page_ in the content folder based
    # on the specified template. _page_ is the relative path to the new page
    # from the <code>content/</code> folder. The _template_ is the name of
    # the template to use from the <code>templates/</code> folder.
    #
    def create( page, opts = {} )
      tmpl = opts[:from]
      raise Error, "template not given" unless tmpl

      name = ::Webby::Resources.basename(page)
      ext  = ::Webby::Resources.extname(page)
      dir  = ::File.dirname(page)
      dir  = '' if dir == '.'

      if tmpl.pathmap('%n') =~ %r/^_/
        page = ::File.join(::Webby.site.content_dir, dir, '_'+name)
        page << '.' << (ext.empty? ? 'txt' : ext)
      elsif ::Webby.site.create_mode == 'directory' and name != 'index'
        page = ::File.join(::Webby.site.content_dir, dir, name, 'index')
        page << '.' << (ext.empty? ? 'txt' : ext)
      else
        page = ::File.join(::Webby.site.content_dir, page)
        page << '.txt' if ext.empty?
      end
      raise Error, "#{page} already exists" if test ?e, page

      Logging::Logger[self].info "creating #{page}"
      FileUtils.mkdir_p ::File.dirname(page)

      context = scope
      opts[:locals].each do |k,v|
        Thread.current[:value] = v
        definition = "#{k} = Thread.current[:value]"
        eval(definition, context)
      end if opts.has_key?(:locals)

      str = ERB.new(::File.read(tmpl), nil, '-').result(context)
      ::File.open(page, 'w') {|fd| fd.write str}

      page
    end

    # call-seq:
    #    Builder.new_page_info    => [page, title, directory]
    #
    def new_page_info
      args = Webby.site.args

      # TODO: maybe even get rid of this method altogether
      raise "Usage:  webby #{args.rake.first} 'path'" if args.raw.empty?

      [args.page, args.title, args.dir]
    end

    private

    # Returns the binding in the scope of the Builder class object.
    #   
    def scope() binding end

  end  # class << self

  # call-seq:
  #    Builder.new
  #
  # Creates a new Builder object for creating pages from the content and
  # layout directories.
  #
  def initialize
    @logger = Logging::Logger[self]
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
    verbose = opts.getopt(:verbose, true)

    unless test(?d, output_dir)
      journal.create output_dir
      FileUtils.mkdir output_dir
    end

    ::Webby.load_files if opts[:load_files]

    Resources.pages.each do |page|
      unless page.dirty? or opts[:rebuild]
        journal.identical(page.destination) if verbose
        next
      end

      # copy the resource to the output directory if it is static
      if page.instance_of? Resources::Static
        FileUtils.mkdir_p ::File.dirname(page.destination)
        journal.create_or_update(page)
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

  def load_files
    ::Webby.deprecated "load_files", "it is being replaced by the Webby#load() method"
    ::Webby.load_files
  end

  %w(output_dir layout_dir content_dir).each do |key|
    self.class_eval <<-CODE
      def #{key}( ) ::Webby.site.#{key} end
    CODE
  end

end  # class Builder
end  # module Webby

# EOF
