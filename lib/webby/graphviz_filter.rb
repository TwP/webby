# $Id$

require 'hpricot'
require 'tempfile'
require 'fileutils'

module Webby

#
# possilbe options to pass in
# - class   => pass to generated HTML
# - id      => pass to generated HTML
# - alt     => pass to generated HTML
# - type    => type of image to generated (jpeg, png, gif, etc)
# - output  => path/to/generated/image.type
# - cmd     => particular graphviz converter to use (dot)
# - imagemap => false or true
#     
class GraphvizFilter

  # call-seq:
  #    GraphvizFilter.new( string, filters = nil )
  #
  # Creates a new Graphviz filter that will operate on the given _string_.
  # The optional _filters_ describe filters that will be applied to the
  # output string returned by the Graphviz filter.
  #
  def initialize( str, filters = nil )
    @str = str
    @filters = filters
  end

  # call-seq:
  #    to_html    => string
  #
  # Process the original text string passed to the filter when it was
  # created and output HTML formatted text. Any text between
  # <graphviz>...</graphviz> tags will have the contained DOT syntax
  # converted into an image and then included into the resulting HTML text.
  #
  def to_html
    doc = Hpricot(@str)
    doc.search('//graphviz') do |gviz|
      
      output = gviz['output']
      raise ArgumentError, "graphviz images must have an output" if output.nil?

      path = File.dirname output
      name = File.basename output, '.*'
      cmd  = gviz['cmd'] || 'dot'
      type = gviz['type'] || 'jpeg'
      image_fn = File.join(path, name) << '.' << type
      usemap = gviz['imagemap'] == 'true'

      out = "<img src=\"#{image_fn}\""

      %w[class style id alt].each do |attr|
        next if gviz[attr].nil?
        out << " %s=\"%s\"" % [attr, gviz[attr]]
      end

      out << " usemap=\"#{name}\"" if usemap
      out << " />\n"

      fd = Tempfile.new('webbydot')
      fd.write(gviz.inner_html.strip)
      fd.close

      # generate the image map
      if usemap
        out << %x[#{cmd} -Tcmapx #{fd.path}]
        out << "\n"

        unless 0 == $?.exitstatus
          raise NameError, "'#{cmd}' not found on the path"
        end
      end

      # generate the image using graphviz -- but first ensure that the
      # path exists
      out_dir = ::Webby.config['output_dir']
      FileUtils.mkpath(File.join(out_dir, path))

      %x[#{cmd} -T#{type} -o #{File.join(out_dir, image_fn)} #{fd.path}]

      unless 0 == $?.exitstatus
        raise NameError, "'#{cmd}' not found on the path"
      end

      # see if we need to put some guards around the output
      # (specifically for textile)
      @filters.each do |f|
        case f
        when 'textile'
          out.insert 0, "<notextile>\n"
          out << "\n</notextile>"
        end
      end unless @filters.nil?

      gviz.swap out
    end

    doc.to_html
  end

end  # class CodeRayFilter
end  # module Webby

# EOF
