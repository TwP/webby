# $Id$

require 'hpricot'
require 'tempfile'
require 'fileutils'

module Webby
module Filters

# The Graphviz filter processes DOT scripts in a webpage and replaces them
# with generated image files. A set of <graphviz>...</graphviz> tags is
# used to denote which section(s) of the page contains DOT scripts.
#
# Options can be passed to the Graphviz filter using attributes in the
# <graphviz> tag.
#
#     <graphviz path="images" type="gif" cmd="dot">
#     digraph graph_1 {
#       graph [URL="default.html"]
#       a [URL="a.html"]
#       b [URL="b.html"]
#       c [URL="c.html"]
#       a -> b -> c
#       a -> c
#     }
#     </graphviz>
#
# If the DOT script contains *URL* or *href* statements on any of the nodes
# or edges, then an image map will be generated and the image will be
# "clikcable" in the webpage. If *URL* or *href* statements do not appear in
# the DOT script, then a regular image will be inserted into the webpage.
#
# The image is inserted into the page using an HTML <img /> tag. A
# corresponding <map>...</map> element will be inserted if needed.
#
# The supported Graphviz options are the following:
#
#    path     : where generated images will be stored
#               [default is "/"]
#    type     : the type of image to generate (png, jpeg, gif)
#               [default is png]
#    cmd      : the Graphviz command to use when generating images
#               (dot, neato, twopi, circo, fdp) [default is dot]
#
#    the following options are passed as-is to the generated <img /> tag
#    style    : CSS styles to apply to the <img />
#    class    : CSS class to apply to the <img />
#    id       : HTML identifier
#    alt      : alternate text for the <img />
#
class Graphviz

  # call-seq:
  #    Graphviz.new( string, filters = nil )
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
      
      text = gviz.inner_html.strip   # the DOT script to process
      path = gviz['path']
      cmd  = gviz['cmd'] || 'dot'
      type = gviz['type'] || 'png'

      # pull the name of the graph|digraph out of the DOT script
      name = text.match(%r/\A\s*(?:strict\s+)?(?:di)?graph\s+([A-Za-z_][A-Za-z0-9_]*)\s+\{/o)[1]

      # see if the user includes any URL or href attributes
      # if so, then we need to create an imagemap
      usemap = text.match(%r/(?:URL|href)\s*=/o) != nil

      # generate the image filename based on the path, graph name, and type
      # of image to generate
      image_fn = path.nil? ? name.dup : File.join(path, name)
      image_fn << '.' << type

      # create the HTML img tag
      out = "<img src=\"#{image_fn}\""

      %w[class style id alt].each do |attr|
        next if gviz[attr].nil?
        out << " %s=\"%s\"" % [attr, gviz[attr]]
      end

      out << " usemap=\"#{name}\"" if usemap
      out << " />\n"

      # write the DOT text out to a temp file for processing by the
      # graphviz programs
      fd = Tempfile.new('webbydot')
      fd.write text
      fd.close

      # generate the image map if needed
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
      FileUtils.mkpath(File.join(out_dir, path)) unless path.nil?

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

end  # class CodeRay
end  # module Filters
end  # module Webby

# EOF
