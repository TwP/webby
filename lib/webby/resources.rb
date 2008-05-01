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
      filename = ::Webby::Resources::File.basename(fn)
      if %r/\A_/o =~ filename
        r = ::Webby::Resources::Partial.new(fn)
        self.partials << r
        return r
      end

      # see if we are dealing with a static resource
      meta = ::Webby::Resources::File.meta_data(fn)
      if meta.nil?
        r = ::Webby::Resources::Static.new(fn)
        self.pages << r
        return r
      end

      # this is a renderable page
      r = ::Webby::Resources::Page.new(fn)
      self.pages << r
      return r
    end

    # Returns a normalized path for the given filename.
    #
    def path( filename )
      filename.sub(%r/\A(?:\.\/|\/)/o, '').freeze
    end

  end  # class << self

end  # module Webby::Resources

Webby.require_all_libs_relative_to(__FILE__)

# EOF
