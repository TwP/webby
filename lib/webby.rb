# $Id$

require 'logging'
require 'ostruct'

# Configure Webby to log to STDOUT at the 'info' level
Logging::Logger['Webby'].level = :info
Logging::Logger['Webby'].add(Logging::Appender.stdout)
Logging::Appender.stdout.layout = Logging::Layouts::Pattern.new(
    :pattern      => "[%d] %5l: %m\n",    # [date] LEVEL: message
    :date_pattern => "%H:%M:%S"           # date == HH:MM:SS
)


module Webby

  VERSION = '0.6.0'   # :nodoc:

  # Path to the Webby package
  PATH = ::File.expand_path(::File.join(::File.dirname(__FILE__), '..'))

  class Error < StandardError; end  # :nodoc:

  # call-seq:
  #    Webby.require_all_libs_relative_to( filename, directory = nil )
  #
  # Utility method used to rquire all files ending in .rb that lie in the
  # directory below this file that has the same name as the filename passed
  # in. Optionally, a specific _directory_ name can be passed in such that
  # the _filename_ does not have to be equivalent to the directory.
  #
  def self.require_all_libs_relative_to( fname, dir = nil )
    dir ||= File.basename(fname, '.*')
    search_me = File.expand_path(
        File.join(File.dirname(fname), dir, '**', '*.rb'))

    Dir.glob(search_me).sort.each {|rb| require rb}
  end

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
        'extension'  => 'html',
        'layout'     => 'default'
      },
      :find_by       => 'title',
      # Items used to deploy the webiste
      :host       => 'user@hostname.tld',
      :remote_dir => '/not/a/valid/dir',
      :rsync_args => %w(-av --delete),
      # Options passed to the 'tidy' program when the tidy filter is used
      :tidy_options => '-indent -wrap 80'
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
  #    cairn    => filename
  #
  # The Webby _cairn_ file is used to mark the last time the content was
  # built into the output directory. It is an empty file; only the
  # modification time of the file is important.
  #
  def self.cairn
    @cairn ||= File.join(site.output_dir, '.cairn')
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


Webby.require_all_libs_relative_to __FILE__

# EOF
