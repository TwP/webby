module Webby::Resources

  class << self
    # Returns the pages hash object.
    #
    def pages
      @pages ||= ::Webby::Resources::DB.new
    end

    # Returns the layouts hash object.
    #
    def layouts
      @layouts ||= ::Webby::Resources::DB.new
    end

    # Returns the partials hash object.
    #
    def partials
      @partials ||= ::Webby::Resources::DB.new
    end

    # Clear the contents of the +layouts+, +pages+ and +partials+ hash
    # objects.
    #
    def clear
      self.pages.clear
      self.layouts.clear
      self.partials.clear
    end

    # call-seq:
    #    Resources.new( filename )
    #
    #
    def new( fn )
      # normalize the path
      fn = self.path(fn)

      # see if we are dealing with a layout
      if %r/\A#{::Webby.site.layout_dir}\//o =~ fn
        r = ::Webby::Resources::Layout.new(fn)
        self.layouts << r
        return r
      end

      # see if we are dealing with a partial
      filename = self.basename(fn)
      if %r/\A_/o =~ filename
        r = ::Webby::Resources::Partial.new(fn)
        self.partials << r
        return r
      end

      begin
        fd = ::File.open(fn, 'r')
        mf = MetaFile.new fd

        # see if we are dealing with a static resource
        unless mf.meta_data?
          r = ::Webby::Resources::Static.new(fn)
          self.pages << r
          return r
        end

        # this is a renderable page
        mf.each do |meta_data|
          r = ::Webby::Resources::Page.new(fn, meta_data)
          self.pages << r
          r
        end
      rescue MetaFile::Error => err
        logger.error "error loading file #{fn.inspect}"
        logger.error err
      ensure
        fd.close if fd
      end
    end

    # Returns a normalized path for the given filename.
    #
    def path( filename )
      filename.sub(%r/\A(?:\.\/|\/)/o, '').freeze
    end

    # Returns the layout resource corresponding to the given _filename_ or
    # +nil+ if no layout exists under that filename.
    #
    def find_layout( filename )
      return unless filename
      filename = filename.to_s

      fn  = self.basename(filename)
      dir = ::File.dirname(filename)
      dir = '.' == dir ? '' : dir

      layouts.find(:filename => fn, :in_directory => dir)

    rescue RuntimeError
      raise Webby::Error, "could not find layout #{filename.inspect}"
    end

    # Returns the directory component of the _filename_ with the content
    # directory removed from the beginning if it is present.
    #
    def dirname( filename )
      rgxp = %r/\A(?:#{::Webby.site.content_dir}|#{::Webby.site.layout_dir})\//o
      dirname = ::File.dirname(filename)
      dirname << '/' if dirname.index(?/) == nil
      dirname.sub(rgxp, '')
    end

    # Returns the last component of the _filename_ with any extension
    # information removed.
    #
    def basename( filename )
      ::File.basename(filename, '.*')
    end

    # Returns the extension (the portion of file name in path after the
    # period). This method excludes the period from the extension name.
    #
    def extname( filename )
      ::File.extname(filename).tr('.', '')
    end

    # :stopdoc:
    def logger
      @logger ||= ::Logging::Logger[self]
    end
    # :startdoc:

  end  # class << self
end  # module Webby::Resources

Webby.require_all_libs_relative_to(__FILE__)

# EOF
