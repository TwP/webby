# Equivalent to a header guard in C/C++
# Used to prevent the spec helper from being loaded more than once
unless defined? ::Webby

begin
  require 'logging'
  require 'loquacious'
rescue LoadError
  retry if require 'rubygems'
  raise
end
require 'date'

module Webby

  # :stopdoc:
  VERSION = '0.9.4.1'   # :nodoc:
  LIBPATH = ::File.expand_path(::File.dirname(__FILE__)) + ::File::SEPARATOR
  PATH = ::File.dirname(LIBPATH) + ::File::SEPARATOR
  YAML_SEP = '---'
  # :startdoc:

  class Error < StandardError; end  # :nodoc:

  # call-seq:
  #    Webby.site    => configuration
  #
  # Returns the configuration parameters for the Webby site. These defaults
  # should be overridden as needed in the site specific Rakefile.
  #
  def self.site
    Loquacious.configuration_for :webby
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
  #    Webby.exec_editor( *args )
  #
  # Calls the editor set in the Sitefile or in the environment variables
  # WEBBY_EDITOR or EDITOR (in that order). This method will do nothing if
  # the editor has not been set.
  #
  def self.exec_editor( *args )
    unless defined? @editor
      @editor = (site.editor.nil? or site.editor.empty?) ? nil : site.editor
      @editor = @editor.split if @editor
    end
    return if @editor.nil?

    args = [@editor, args].flatten
    exec(*args)
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
    args.empty? ? LIBPATH : ::File.join(LIBPATH, args.flatten)
  end

  # Returns the path for Webby. If any arguments are given,
  # they will be joined to the end of the path using
  # <tt>File.join</tt>.
  #
  def self.path( *args )
    args.empty? ? PATH : ::File.join(PATH, args.flatten)
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

  # Scan the <code>layouts/</code> folder and the <code>content/</code>
  # folder and create a new Resource object for each file found there.
  #
  def self.load_files
    ::Find.find(site.layout_dir, site.content_dir) do |path|
      next unless test ?f, path
      next if path =~ ::Webby.exclude
      Resources.new path
    end
  end

end  # module Webby


# call-seq:
#    try_require( library, gemname = nil )    => true or false
#
# Try to laod the given _library_ using the built-in require, but do not
# raise a LoadError if unsuccessful. Returns +true+ if the _library_ was
# successfully loaded; returns +false+ otherwise.
#
# If a _gemname_ is given, then the "gem gemname" command will be called
# before the library is loaded.
#
def try_require( lib, gemname = nil )
  gem gemname unless gemname.nil?
  require lib
  true
rescue LoadError
  false
end

Webby.require_all_libs_relative_to(__FILE__, ::File.join(%w[webby core_ext]))
Webby.require_all_libs_relative_to(__FILE__)

end  # unless defined?

# EOF
