# $Id$

require 'hpricot'
require 'open-uri'

module Webby

# The Webby LinkValidator class is used to validate the hyperlinks of all
# the HTML files in the output directory. By default, only links to other
# pages in the output directory are checked. However, setting the
# :external flag to +true+ will cause hyperlinks to external web sites to
# be validated as well.
#
class LinkValidator

  # A lazy man's method that will instantiate a new link validator and run
  # the validations.
  #
  def self.validate( opts = {} )
    new(opts).validate
  end

  attr_accessor :validate_externals

  # call-seq:
  #    LinkValidator.new( opts = {} )
  #
  # Creates a new LinkValidator object. The only supported option is the
  # :external flag. When set to +true+, the link validator will also check
  # out links to external websites. This is done by opening a connection to
  # the remote site and pulling down the page specified in the hyperlink.
  # Use with caution.
  #
  def initialize( opts = {} )
    @log = Logging::Logger[self]

    glob = ::File.join(::Webby.site.output_dir, '**', '*.html')
    @files = Dir.glob(glob).sort
    @attr_rgxp = %r/\[@(\w+)\]$/o

    @validate_externals = opts.getopt(:external, false)
  end

  # Iterate over all the HTML files in the output directory and validate the
  # hyperlinks.
  #
  def validate
    @files.each {|fn| check_file fn}
  end

  # Check the given file (identified by its filename {fn for short here}) by
  # iterating through all the configured xpaths and validating that those
  # hyperlinks ae valid.
  #
  def check_file( fn )
    @log.info "validating #{fn}"

    dir = ::File.dirname(fn)
    doc = Hpricot(::File.read(fn))

    ::Webby.site.xpaths.each do |xpath|
      @attr_name = nil

      doc.search(xpath).each do |element|
        @attr_name ||= @attr_rgxp.match(xpath)[1]
        uri = URI.parse(element.get_attribute(@attr_name))
        validate_uri(uri, dir)
      end
    end
  end

  # Validate the the page the _uri_ refers to actually exists. The directory
  # of the current page being processed is needed in order to resolve
  # relative paths. 
  #
  # If the _uri_ is a relative path, then the output directory is searched
  # for the appropriate page. If the _uri_ is an absolute path, then the
  # remote server is contacted and the page requested from the server. This
  # will only take place if the LinkValidator was created with the :external
  # flag set to true.
  #
  def validate_uri( uri, dir )
    # for relative URIs, we can see if the file exists in the output folder
    if uri.relative?
      return if uri.path.empty?

      path = if uri.path =~ %r/^\//
          ::File.join(::Webby.site.output_dir, uri.path)
        else
          ::File.join(dir, uri.path)
        end

      path = ::File.join(path, 'index.html') if ::File.extname(path).empty?
      unless test ?f, path
        @log.error "invalid URI '#{uri.to_s}'"
      end

    # if the URI responds to the open mehod, then try to access the URI
    elsif uri.respond_to? :open
      return unless @validate_externals
      begin
        uri.open {|_| nil}
      rescue Exception
        @log.error "could not open URI '#{uri.to_s}'"
      end 

    # otherwise, post a warning that the URI could not be validated
    else
      @log.warn "could not validate URI '#{uri.to_s}'"
    end
  end

end  # class LinkValidator
end  # module Webby

# EOF
