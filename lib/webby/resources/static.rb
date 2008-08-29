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

  # :stopdoc:
  def _read
    ::File.read(path)
  end
  # :startdoc:

end  # class Layout
end  # module Webby::Resources

# EOF
