# $Id$

module Webby

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
  #    Webby.config    => hash
  #
  # Returns the configuration hash for the Webby application.
  #--
  # The defaults are defined in the lib/webby/webby_task.rb file
  #++
  def self.config
    @config ||= {}
  end

  # call-seq:
  #    Webby.page_defaults    => hash
  #
  # Returns the page defaults hash used for page resource objects.
  #--
  # The defaults are defined in the lib/webby/webby_task.rb file
  #++
  def self.page_defaults
    @page_defaults ||= {}
  end

end  # module Webby


Webby .require_all_libs_relative_to __FILE__

# EOF
