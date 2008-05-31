require Webby.libpath(*%w[webby stelan mktemp])
require 'fileutils'

module Webby::Helpers
module TexImgHelper

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

    text = capture_erb(&block)
    return if text.empty?

    defaults = ::Webby.site.tex2img
    path = opts.getopt(:path, defaults[:path])
    type = opts.getopt(:type, defaults[:type])
    bg   = opts.getopt(:bg, defaults[:bg])
    fg   = opts.getopt(:fg, defaults[:fg])
    res  = opts.getopt(:resolution, defaults[:resolution])

    # fix color escaping
    fg = fg =~ %r/^[a-zA-Z]+$/ ? fg : "\"#{fg}\""
    bg = bg =~ %r/^[a-zA-Z]+$/ ? bg : "\"#{bg}\""

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
      \\nonstopmode
      \\documentclass{article}
      \\usepackage[T1]{fontenc}
      \\usepackage{amsmath,amsfonts,amssymb,wasysym,latexsym,marvosym,txfonts}
      \\usepackage[pdftex]{color}
      \\pagestyle{empty}
      \\begin{document}
      \\fontsize{12}{24}
      \\selectfont
      \\color{white}
      \\pagecolor{black}
      \\[
      #{text}
      \\]
      \\end{document}
    TEX
    tex.gsub!(%r/\n\s+/, "\n").strip!

    # make a temporarty directory to store all the TeX files
    pwd = Dir.pwd
    tmpdir = ::Webby::MkTemp.mktempdir('tex2img_XXXXXX')

    begin
      Dir.chdir(tmpdir)
      File.open('out.tex', 'w') {|fd| fd.puts tex}
      dev_null = test(?e, "/dev/null") ? "/dev/null" : "NUL:"

      %x[pdflatex -interaction=batchmode out.tex &> #{dev_null}]

      convert =  "\\( -density #{res} out.pdf -trim +repage \\) "
      convert << "\\( +clone -fuzz 100% -fill #{fg} -opaque black \\) "
      convert << "+swap -compose copy-opacity -composite "
      convert << "\\( +clone -fuzz 100% -fill #{bg} -opaque white +matte \\) "
      convert << "+swap -compose over -composite #{out_file}"
      %x[convert #{convert} &> #{dev_null}]
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

    # put some guards around the output (specifically for textile)
    out = _guard(out)

    concat_erb(out, block.binding)
    return
  end
end  # module TexImgHelper

%x[pdflatex --version 2>&1]
if 0 == $?.exitstatus
  %x[convert --version 2>&1]
  if 0 == $?.exitstatus
    register(TexImgHelper)
  end
end

end  # module Webby::Helpers

# EOF
