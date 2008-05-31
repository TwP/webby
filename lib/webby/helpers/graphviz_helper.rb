require 'fileutils'
require 'tempfile'

module Webby::Helpers
module GraphvizHelper

  # call-seq:
  #    GraphvizHelper.error_check( file )
  #
  # Check the temporary error file to see if it contains any error messages
  # from the graphviz program. If it is not empty, then read the contents
  # and log an error message and raise an exception.
  #
  def self.error_check( file )
    if ::File.size(file.path) != 0
      msg = "\n" << ::File.read(file.path).strip
      raise ::Webby::Error, msg
    end
  end

  # The +graphviz+ method processes DOT scripts in a webpage and replaces them
  # with generated image files. The page sections to be processed are given
  # as blocks of text to the +graphviz+ method.
  #
  # Options can be passed to the Graphviz program using attributes in the
  # +graphviz+ method.
  #
  #     <% graphviz( :path => "images", :type => "gif", cmd => "dot" ) do %>
  #     digraph graph_1 {
  #       graph [URL="default.html"]
  #       a [URL="a.html"]
  #       b [URL="b.html"]
  #       c [URL="c.html"]
  #       a -> b -> c
  #       a -> c
  #     }
  #     <% end %>
  #
  # If the DOT script contains *URL* or *href* attributes on any of the nodes
  # or edges, then an image map will be generated and the image will be
  # "clikcable" in the webpage. If *URL* or *href* attributes do not appear in
  # the DOT script, then a regular image will be inserted into the webpage.
  #
  # The image is inserted into the page using an HTML <img /> tag. A
  # corresponding <map>...</map> element will be inserted if needed.
  #
  # The supported Graphviz options are the following:
  #
  #    :path     : where generated images will be stored
  #                [default is "/"]
  #    :type     : the type of image to generate (png, jpeg, gif)
  #                [default is png]
  #    :cmd      : the Graphviz command to use when generating images
  #                (dot, neato, twopi, circo, fdp) [default is dot]
  #
  #    the following options are passed as-is to the generated <img /> tag
  #    :style    : CSS styles to apply to the <img />
  #    :class    : CSS class to apply to the <img />
  #    :id       : HTML identifier
  #    :alt      : alternate text for the <img />
  #
  def graphviz( *args, &block )
    opts = args.last.instance_of?(Hash) ? args.pop : {}

    text = capture_erb(&block)
    return if text.empty?

    # create a temporary file for holding any error messages
    # from the graphviz program
    err = Tempfile.new('graphviz_err')
    err.close

    defaults = ::Webby.site.graphviz
    path = opts.getopt(:path, defaults[:path])
    cmd  = opts.getopt(:cmd, defaults[:cmd])
    type = opts.getopt(:type, defaults[:type])

    # pull the name of the graph|digraph out of the DOT script
    name = text.match(%r/\A\s*(?:strict\s+)?(?:di)?graph\s+([A-Za-z_][A-Za-z0-9_]*)\s+\{/o)[1]

    # see if the user includes any URL or href attributes
    # if so, then we need to create an imagemap
    usemap = text.match(%r/(?:URL|href)\s*=/o) != nil

    # generate the image filename based on the path, graph name, and type
    # of image to generate
    image_fn = path.nil? ? name.dup : ::File.join(path, name)
    image_fn = ::File.join('', image_fn) << '.' << type

    # create the HTML img tag
    out = "<img src=\"#{image_fn}\""

    %w[class style id alt].each do |atr|
      val = opts.getopt(atr)
      next if val.nil?
      out << " %s=\"%s\"" % [atr, val]
    end

    out << " usemap=\"\##{name}\"" if usemap
    out << " />\n"

    # generate the image map if needed
    if usemap
      IO.popen("#{cmd} -Tcmapx 2> #{err.path}", 'r+') do |io|
        io.write text
        io.close_write
        out << io.read
      end
      GraphvizHelper.error_check(err)
    end

    # generate the image using graphviz -- but first ensure that the
    # path exists
    out_dir = ::Webby.site.output_dir
    out_file = ::File.join(out_dir, image_fn)
    FileUtils.mkpath(::File.join(out_dir, path)) unless path.nil?
    cmd = "#{cmd} -T#{type} -o #{out_file} 2> #{err.path}"

    IO.popen(cmd, 'w') {|io| io.write text}
    GraphvizHelper.error_check(err)

    # put some guards around the output (specifically for textile)
    out = _guard(out)

    concat_erb(out, block.binding)
    return
  end
end  # module GraphvizHelper

%x[dot -V 2>&1]
if 0 == $?.exitstatus
  register(GraphvizHelper)
end

end  # module Webby::Helpers

# EOF
