require Webby.libpath(*%w[webby resources resource])

module Webby::Resources

# A Partial is a file in the content folder whose filename starts with an
# underscore "_" character. Partials contain text that can be included into
# other pages. Partials are not standalone pages, and they will never
# correspond directly to an output file.
#
# Partials can contain YAML meta-data at the top of the file. This
# information is only used to determine the filters to apply to the
# partial. If there is no meta-data, then the partial text is used "as is"
# without any processing by the Webby rendering engine.
#
class Partial < Resource

  # call-seq:
  #    Partial.new( path )
  #
  # Creates a new Partial object given the full path to the partial file.
  # Partial filenames start with an underscore (this is an enforced
  # convention).
  #
  def initialize( fn )
    super

    @mdata = ::Webby::Resources::File.meta_data(@path)
    @mdata ||= {}
    @mdata.sanitize!
  end

  # call-seq:
  #    dirty?    => true or false
  #
  # Returns +true+ if this resource is newer than its corresponding output
  # product. The resource needs to be rendered (if a page or layout) or
  # copied (if a static file) to the output directory.
  #
  def dirty?
    return @mdata['dirty'] if @mdata.has_key? 'dirty'

    # if the destination file does not exist, then we are dirty
    return true unless test(?e, destination)

    # if this file's mtime is larger than the destination file's
    # mtime, then we are dirty
    dirty = @mtime > ::File.mtime(destination)
    return dirty if dirty

    # if we got here, then we are not dirty
    false
  end

  # call-seq:
  #    destination    => string
  #
  # The output file destination for the partial. This is the ".cairn" file in
  # the output folder. It is used to determine if the partial is newer than
  # the build products.
  #
  def destination
    ::Webby.cairn
  end

  alias :extension :ext

  # call-seq:
  #    url    => nil
  #
  # Partials do not have a URL. This method will alwasy return +nil+.
  #
  def url
    nil
  end

end  # class Partial
end  # module Webby::Resources

# EOF
