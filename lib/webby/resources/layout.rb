require Webby.libpath(*%w[webby resources resource])

module Webby::Resources

# A Layout is any file that is found in the layout folder of the webiste
# directory. Layouts container the common elements of all the pages in a
# website, and pages from the content folder are rendered into the layout.
#
class Layout < Resource

  # call-seq:
  #    Layout.new( path )
  #
  # Creates a new Layout object given the full path to the layout file.
  #
  def initialize( fn )
    super

    @mdata = MetaFile.meta_data(@path)
    @mdata ||= {}
    @mdata.sanitize!
  end

  # call-seq:
  #    destination    => string
  #
  # The output file destination for the layout. This is the ".cairn" file in
  # the output folder. It is used to determine if the layout is newer than
  # the build products.
  #
  def destination
    ::Webby.cairn
  end

  # call-seq:
  #    extension    => string or nil
  #
  # Returns the extension to be applied to output files rendered by the
  # layotut. This will either be a string or +nil+ if the layout does not
  # specify an extension to use.
  #
  def extension
    return @mdata['extension'] if @mdata.has_key? 'extension'

    if @mdata.has_key? 'layout'
      lyt = ::Webby::Resources.find_layout(@mdata['layout'])
      ext = lyt ? lyt.extension : nil
    end
  end

  # call-seq:
  #    url    => nil
  #
  # Layouts do not have a URL. This method will alwasy return +nil+.
  #
  def url
    nil
  end

  # :stopdoc:
  def _read
    MetaFile.read(@path)
  end
  # :startdoc:
  #
end  # class Layout
end  # module Webby::Resources

# EOF
