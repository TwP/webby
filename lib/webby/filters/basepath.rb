# $Id$

require 'hpricot'

module Webby
module Filters

# The BasePath filter is used to rewrite URI paths in HTML documents. This
# is useful when the server location of the website is not located at the
# root of the webserver (e.g. http://my.site.com/foo/bar).
#
# The BasePath filter will adjust the URI paths in a given HTML document by
# prepending a base path to the URI. This only works for URIs that start
# with a leading slash "/". Any other character will exclude the URI from
# being modified.
#
# Assume the user specifies a new URI base in the <tt>Webby.site.base</tt>
# property:
#
#    Webby.site.base = '/foo/bar'
#
# Here is a snippet from some HTML document.
#
#    <a href="/some/other/page.html">Page</a>
#    <img src="fractal.jpg" alt="a fractal" />
#
# When run through the BasePath filter, the resulting snippet would look
# like this.
#
#    <a href="/foo/bar/some/other/page.html">Page</a>
#    <img src="fractal.jpg" alt="a fractal" />
#
# The +href+ attribute of the anchor tag is modified because it started
# with a leading slash. The +src+ attribute of the image tag is not
# modified because it lacks the leading slash.
#
class BasePath

  # call-seq:
  #    BasePath.new( html )
  #
  # Creates a new BasePath filter that will operate on the given _html_
  # string.
  #
  def initialize( str )
    @str = str
  end

  # call-seq:
  #    filter    => html
  #
  # Process the original html document passed to the filter when it was
  # created. The document will be scanned and the basepath for certain
  # elements will be modified.
  #
  # For example, if a document contains the following line:
  # 
  #    <a href="/link/to/another/page.html">Page</a>
  #
  # and the user has requested for the base path to be some other directory
  # on the webserver -- <tt>/some/other/directory</tt>. The result of the
  # BasePath filter would be:
  #
  #     <a href="/some/other/directory/link/to/another/page.html">Page</a>
  #
  def filter
    doc = Hpricot(@str)
    base_path = ::Webby.site.base
    attr_rgxp = %r/\[@(\w+)\]$/o
    sub_rgxp = %r/\A(?=\/)/o

    ::Webby.site.xpaths.each do |xpath|
      @attr_name = nil

      doc.search(xpath).each do |element|
        @attr_name ||= attr_rgxp.match(xpath)[1]
        a = element.get_attribute(@attr_name)
        element.set_attribute(@attr_name, a) if a.sub!(sub_rgxp, base_path)
      end
    end

    doc.to_html
  end

end  # class BasePath

# Rewrite base URIs in the input HTML text.
#
register :basepath do |input, cursor|
  if ::Webby.site.base then BasePath.new(input).filter
  else input end
end

end  # module Filters
end  # module Webby

# EOF
