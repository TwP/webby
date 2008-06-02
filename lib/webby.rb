# Equivalent to a header guard in C/C++
# Used to prevent the spec helper from being loaded more than once
unless defined? ::Webby

require 'rubygems'
require 'logging'
require 'ostruct'
require 'date'

# Configure Webby to log to STDOUT at the 'info' level
Logging::Logger['Webby'].level = :info
Logging::Logger['Webby'].add_appenders(Logging::Appender.stdout)
Logging::Appender.stdout.layout = Logging::Layouts::Pattern.new(
    :pattern      => "[%d] %5l: %m\n",    # [date] LEVEL: message
    :date_pattern => "%H:%M:%S"           # date == HH:MM:SS
)

module Webby

  # :stopdoc:
  VERSION = '0.9.0'   # :nodoc:
  LIBPATH = ::File.expand_path(::File.dirname(__FILE__)) + ::File::SEPARATOR
  PATH = ::File.dirname(LIBPATH) + ::File::SEPARATOR
  # :startdoc:

  class Error < StandardError; end  # :nodoc:

  # call-seq:
  #    Webby.site    => struct
  #
  # Returns a struct containing the configuration parameters for the 
  # Webby site. These defaults should be overridden as needed in the
  # site specific Rakefile.
  #
  def self.site
    return @site if defined? @site
    @site = OpenStruct.new(
      :output_dir    => 'output',
      :content_dir   => 'content',
      :layout_dir    => 'layouts',
      :template_dir  => 'templates',
      :exclude       => %w(tmp$ bak$ ~$ CVS \.svn),
      :page_defaults => {
        'layout'     => 'default'
      },
      :find_by       => 'title',
      :base          => nil,
      :create_mode   => 'page',
      :blog_dir      => 'blog',

      # Items for running the heel webserver
      :heel_port => 4331,

      # Items used to deploy the website
      :user       => ENV['USER'] || ENV['USERNAME'],
      :host       => 'example.com',
      :remote_dir => '/not/a/valid/dir',
      :rsync_args => %w(-av),

      # Global options for HAML and SASS
      :haml_options => {},
      :sass_options => {},

      # Options passed to the 'tidy' program when the tidy filter is used
      :tidy_options => '-indent -wrap 80',

      # List of valid URIs (these automatically pass validation)
      :valid_uris => [],

      # Options for coderay processing
      :coderay => {
        :lang => :ruby,
        :line_numbers => nil,
        :line_number_start => 1,
        :bold_every => 10,
        :tab_width => 8
      },

      # Options for graphviz processing
      :graphviz => {
        :path => nil,
        :cmd => 'dot',
        :type => 'png'
      },

      # Options for tex2img processing
      :tex2img => {
        :path => nil,
        :type => 'png',
        :bg => 'white',
        :fg => 'black',
        :resolution => '150x150'
      },

      # Options for ultraviolet syntax highlighting
      :uv => {
        :lang => 'ruby',
        :line_numbers => false,
        :theme => 'mac_classic'
      },

      # XPath identifiers used by the basepath filter
      :xpaths => %w(
          /html/head//base[@href]
          /html/head//link[@href]
          //script[@src]
          /html/body[@background]
          /html/body//a[@href]
          /html/body//object[@data]
          /html/body//img[@src]
          /html/body//area[@href]
          /html/body//form[@action]
          /html/body//input[@src]
      )
      # other possible XPaths to include for base path substitution
      #   /html/body//object[@usemap]
      #   /html/body//img[@usemap]
      #   /html/body//input[@usemap]
    )
  end

  # call-seq
  #    Webby.exclude    => regexp
  #
  # Returns a regular expression used to exclude resources from the content
  # directory from being processed by Webby. This same regular expression is
  # also used to exclude layouts.
  #
  def self.exclude
    @exclude ||= Regexp.new(site.exclude.join('|'))
  end

  # call-seq:
  #    Webby.editor    => string or nil
  #
  # Returns the default editor to use when creating new pages. This editor
  # will be spawned to allow the user to edit the newly created page.
  #
  def self.editor
    return @editor if defined? @editor

    @editor = if ENV['EDITOR'].nil? or ENV['EDITOR'].empty? then nil
              else ENV['EDITOR'] end
  end

  # call-seq:
  #    cairn    => filename
  #
  # The Webby _cairn_ file is used to mark the last time the content was
  # built into the output directory. It is an empty file; only the
  # modification time of the file is important.
  #
  def self.cairn
    @cairn ||= ::File.join(site.output_dir, '.cairn')
  end

  # Returns the library path for Webby. If any arguments are given,
  # they will be joined to the end of the libray path using
  # <tt>File.join</tt>.
  #
  def self.libpath( *args )
    args.empty? ? LIBPATH : ::File.join(LIBPATH, *args)
  end

  # Returns the path for Webby. If any arguments are given,
  # they will be joined to the end of the path using
  # <tt>File.join</tt>.
  #
  def self.path( *args )
    args.empty? ? PATH : ::File.join(PATH, *args)
  end

  # call-seq:
  #    Webby.require_all_libs_relative_to( filename, directory = nil )
  #
  # Utility method used to rquire all files ending in .rb that lie in the
  # directory below this file that has the same name as the filename passed
  # in. Optionally, a specific _directory_ name can be passed in such that
  # the _filename_ does not have to be equivalent to the directory.
  #
  def self.require_all_libs_relative_to( fname, dir = nil )
    dir ||= ::File.basename(fname, '.*')
    search_me = ::File.expand_path(
        ::File.join(::File.dirname(fname), dir, '*.rb'))

    Dir.glob(search_me).sort.each {|rb| require rb}
  end

  # Prints a deprecation warning using the logger. The message states that
  # the given method is being deprecated. An optional message can be give to
  # -- somthing nice and fuzzy about a new method or why this one has to go
  # away; sniff, we'll miss you little buddy.
  #
  def self.deprecated( method, message = nil )
    msg = "'#{method}' has been deprecated"
    msg << "\n\t#{message}" unless message.nil?
    Logging::Logger['Webby'].warn msg
  end

end  # module Webby


# call-seq:
#    try_require( library )    => true or false
#
# Try to laod the given _library_ using the built-in require, but do not
# raise a LoadError if unsuccessful. Returns +true+ if the _library_ was
# successfully loaded; returns +false+ otherwise.
#
def try_require( lib )
  require lib
  true
rescue LoadError
  false
end

Webby.require_all_libs_relative_to(__FILE__)

end  # unless defined?

# EOF
