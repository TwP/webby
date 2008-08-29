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

    @_meta_data = MetaFile.meta_data(@path)
    @_meta_data ||= {}
    @_meta_data.sanitize!
  end

  # Returns the extension to be applied to output files rendered by the
  # layotut. This will either be a string or +nil+ if the layout does not
  # specify an extension to use.
  #
  def extension
    return _meta_data['extension'] if _meta_data.has_key? 'extension'

    if _meta_data.has_key? 'layout'
      lyt = ::Webby::Resources.find_layout(_meta_data['layout'])
      lyt ? lyt.extension : nil
    end
  end

  # The output file destination for the layout. This is the ".cairn" file in
  # the output folder. It is used to determine if the layout is newer than
  # the build products.
  #
  def destination
    ::Webby.cairn
  end

  # Layouts do not have a URL. This method will alwasy return +nil+.
  #
  def url
    nil
  end

end  # class Layout
end  # module Webby::Resources

# EOF
