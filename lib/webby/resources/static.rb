require Webby.libpath(*%w[webby resources resource])

module Webby::Resources

# A Static resource is any file in the content folder that does not
# contain YAML meta-data at the top of the file and does not start with
# and underscore "_" character (those are partials). Static resources will
# be copied as-is from the content directory to the output directory.
#
class Static < Resource

  # call-seq:
  #    render   => string
  #
  # Returns the contents of the file.
  #
  def render
    ::File.read(path)
  end

  # call-seq:
  #    dirty?    => true or false
  #
  # Returns +true+ if this static file is newer than its corresponding output
  # product. The static file needs to be copied to the output directory.
  #
  def dirty?
    return true unless test(?e, destination)
    @mtime > ::File.mtime(destination)
  end

  # call-seq:
  #    destination    => string
  #
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

end  # class Layout
end  # module Webby::Resources

# EOF
