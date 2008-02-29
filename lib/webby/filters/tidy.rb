# $Id$

require 'fileutils'
require 'tempfile'

module Webby
module Filters

# The Tidy filter is used to process HTML (or XHTML) through the _tidy_
# program and outpu nicely formatted and correct HTML (or XHTML).
#
# Options can be passed to the _tidy_ program via the
# <code>Webby.site</code> struct. Setting the +tidy_options+ to the string
# of desired options will do the trick.
#
# From a project's Rakefile, include the following line (or one that's more
# to your liking):
#
#    SITE.tidy_options = "-indent -wrap 80 -utf8"
#
class Tidy

  # :stopdoc:
  class Error < StandardError; end
  # :startdoc:

  # call-seq:
  #    Tidy.new( html )
  #
  # Create a new filter that will process the given _html_ through the tidy
  # program.
  #
  def initialize( str )
    @log = ::Logging::Logger[self]
    @str = str

    # create a temporary file for holding any error messages
    # from the tidy program
    @err = Tempfile.new('tidy_err')
    @err.close
  end

  # call-seq:
  #    process    => formatted html
  #
  # Process the original HTML text string passed to the filter when it was
  # created and output Tidy formatted HTML or XHTML.
  #
  def process
    %x[tidy -v 2>&1]
    unless 0 == $?.exitstatus
      raise NameError, "'tidy' not found on the path"
    end

    cmd = "tidy %s -q -f #{@err.path}" % ::Webby.site.tidy_options
    out = IO.popen(cmd, 'r+') do |tidy|
      tidy.write @str
      tidy.close_write
      tidy.read
    end

    if File.size(@err.path) != 0
      @log.warn File.read(@err.path).strip
    end

    return out
  end

end  # class Tidy

# Render html into html/xhtml via the Tidy program
#
register :tidy do |input|
  Filters::Tidy.new(input).process
end

end  # module Filters
end  # module Webby

# EOF
