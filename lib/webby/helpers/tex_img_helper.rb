# $Id$

require Webby.libpath(*%w[webby stelan mktemp])
require 'fileutils'
require 'tempfile'

module Webby::Helpers
module TexImgHelper

  class Error < StandardError; end    # :nodoc:

  # The +tex2img+ method converts a a section of mathematical TeX script
  # into an image and embeds the resulting image into the page. The TeX
  # engine must be installed on your system along with the ImageMagick
  # +convert+ program.
  #
  # Options can be passed to the TeX engine via attributes in the
  # +tex2img+ method.
  #
  #    <% tex2img( "wave_eq", :path => "images", :alt => "wave equation" ) do -%>
  #      $\psi_{tot}(x,-t_0,r) = \frac{1}{(2\pi)^2} \int\!\!\!\int
  #      \tilde\Psi_{tot}\left(k_x,\frac{c}{2}\sqrt{k_x^2 + k_r^2},r=0\right)$
  #    <% end -%>
  #    
  # The supported TeX options are the following:
  #
  #    :path         : where generated images will be stored
  #                    [default is "/"]
  #    :type         : the type of image to generate (png, jpeg, gif)
  #                    [default is png]
  #    :bg           : the background color of the image (color name,
  #                    TeX color spec, or #aabbcc) [default is white]
  #    :fg           : the foreground color of the image (color name,
  #                    TeX color spec, or #aabbcc) [default is black]
  #    :resolution   : the desired resolution in dpi (HxV)
  #                    [default is 150x150]
  #    :antialias    : if false, disables anti-aliasing in the resulting image
  #                    [default is true]
  #
  #    the following options are passed as-is to the generated <img /> tag
  #    :style    : CSS styles to apply to the <img />
  #    :class    : CSS class to apply to the <img />
  #    :id       : HTML identifier
  #    :alt      : alternate text for the <img />
  #
  def tex2img( *args, &block )
    opts = args.last.instance_of?(Hash) ? args.pop : {}
    name = args.first
    raise 'TeX graphics must have a name' if name.nil?

    buffer = eval('_erbout', block.binding)
    pos = buffer.length
    block.call(*args)

    text = buffer[pos..-1].strip
    if text.empty?
      buffer[pos..-1] = ''
      return
    end

    # create a temporary file for holding any error messages
    # from the graphviz program
    err = Tempfile.new('graphviz_err')
    err.close

    path  = opts.getopt(:path)
    type  = opts.getopt(:type, 'png')
    bg    = opts.getopt(:bg, 'white')
    fg    = opts.getopt(:fg, 'black')
    res   = opts.getopt(:resolution, '150x150')
    aa    = opts.getopt(:antialias, true)

    # fix the color escaping
    fg = TexImgHelper.tex_color(fg)
    bg = TexImgHelper.tex_color(bg)

    # generate the image filename based on the path, graph name, and type
    # of image to generate
    image_fn = path.nil? ? name.dup : ::File.join(path, name)
    image_fn = ::File.join('', image_fn) << '.' << type

    # generate the image using convert -- but first ensure that the
    # path exists
    out_dir = ::Webby.site.output_dir
    out_file = ::File.join('..', out_dir, image_fn)
    FileUtils.mkpath(::File.join(out_dir, path)) unless path.nil?

    tex = <<-TEX
      \\documentclass[12pt]{article}
      \\usepackage[usenames,dvipsnames]{color}
      \\usepackage[dvips]{graphicx}
      \\pagestyle{empty}
      \\pagecolor#{bg}
      \\begin{document}
      {\\color#{fg}
      #{text}
      }\\end{document}
    TEX
    tex.gsub!(%r/\n\s+/, "\n").strip!

    # make a temporarty directory to store all the TeX files
    pwd = Dir.pwd
    tmpdir = ::Webby::MkTemp.mktempdir('tex2img_XXXXXX')

    begin
      Dir.chdir(tmpdir)
      File.open('out.tex', 'w') {|fd| fd.puts tex}
      dev_null = test(?e, "/dev/null") ? "/dev/null" : "NUL:"

      %x[latex -interaction=batchmode out.tex &> #{dev_null}]
      %x[dvips -o out.eps -E out.dvi &> #{dev_null}]
      %x[convert +adjoin #{aa ? '-antialias' : '+antialias'} -density #{res} out.eps #{out_file} &> #{dev_null}]
    ensure
      Dir.chdir(pwd)
      FileUtils.rm_rf(tmpdir) if test(?e, tmpdir)
    end

    # generate the HTML img tag to insert back into the document
    out = "<img src=\"#{image_fn}\""
    %w[class style id alt].each do |atr|
      val = opts.getopt(atr)
      next if val.nil?
      out << " %s=\"%s\"" % [atr, val]
    end
    out << " />\n"

    if @_cursor.remaining_filters.include? 'textile'
      out.insert 0, "<notextile>\n"
      out << "\n</notextile>"
    end

    buffer[pos..-1] = out
    return
  ensure
  end

  # call-seq:
  #    TexImgHelper.tex_color( string )    => string
  #
  # Taken the given color _string_ and convert it to a TeX color spec. The
  # input string can be either a RGB Hex value, a TeX color spec, or a color
  # name.
  #
  #    tex_color( '#666666' )         #=> [rgb]{0.4,0.4,0.4}
  #    tex_color( 'Tan' )             #=> {Tan}
  #    tex_color( '[rgb]{1,0,0}' )    #=> [rgb]{1,0,0}
  #
  # This is an example of an invalid Hex RGB color -- they must contain six
  # hexidecimal characters to be valid.
  #
  #    tex_color( '#333' )            #=> {#333}
  #
  def self.tex_color( color )
    case color
    when %r/^#([A-Fa-f0-9]{6})/o
      hex = $1
      rgb = []
      hex.scan(%r/../) {|n| rgb << Float(n.to_i(16))/255.0}
      "[rgb]{#{rgb.join(',')}}"
    when %r/^[\{\[]/o
      "{#{color}}"
    else
      color
    end
  end

end  # module TexImgHelper

%x[latex --version 2>&1]
if 0 == $?.exitstatus
  %x[convert --version 2>&1]
  if 0 == $?.exitstatus
    register(TexImgHelper)
  end
end

end  # module Webby::Helpers

# EOF
