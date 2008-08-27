require Webby.libpath(*%w[webby resources resource])

module Webby::Resources

# A Static resource is any file in the content folder that does not
# contain YAML meta-data at the top of the file and does not start with
# and underscore "_" character (those are partials). Static resources will
# be copied as-is from the content directory to the output directory.
#
class Static < Resource

  # Returns the contents of the file.
  #
  def render
    Webby.deprecated "render", "it is being replaced by the Renderer#render() method"
    self._read
  end

  # Returns +true+ if this static file is newer than its corresponding output
  # product. The static file needs to be copied to the output directory.
  #
  def dirty?
    return true unless test(?e, destination)
    @mtime > ::File.mtime(destination)
  end

  # Returns the path in the output directory where the static file should
  # be copied. This path is used to determine if the static file is dirty
  # and in need of copying to the output file.
  #
  def destination
    return @dest if defined? @dest and @dest

    @dest = ::File.join(::Webby.site.output_dir, dir, filename)
    @dest << '.' << @ext if @ext and !@ext.empty?
    @dest
  end

  alias :extension :ext

  # :stopdoc:
  def _read
    ::File.read(path)
  end
  # :startdoc:

end  # class Layout
end  # module Webby::Resources

# EOF
