# $Id$

require 'directory_watcher'

module Webby

# The AutoBuilder class is used to monitor the content and layouts folders
# and to compile the resource files only when they are modified. If a
# layout is modified, then all resources that depend upon the layout are
# compiled.
#
class AutoBuilder

  # call-seq:
  #    AutoBuilder.run
  #
  # Creates a new AutoBuilder and sets it running. This method will only
  # return when the user presses Ctrl-C.
  #
  def self.run
    self.new.run
  end

  # call-seq:
  #    AutoBuilder.new
  #
  # Create a new AutoBuilder class.
  #
  def initialize
    @log = Logging::Logger[self]

    @builder = Builder.new
    @watcher = DirectoryWatcher.new '.', :interval => 2
    @watcher.add_observer self

    glob = []
    glob << File.join(::Webby.site.layout_dir, '**', '*')
    glob << File.join(::Webby.site.content_dir, '**', '*')
    @watcher.glob = glob
  end

  # call-seq:
  #    update( *events )
  #
  # The update method is called by the DirectoryWatcher when files have been
  # modified, added, or deleted. An array of events is passed to his method,
  # and each event contains the event type and the path to the file.
  #
  def update( *events )
    ary = events.find_all {|evt| evt.type != :removed}
    return if ary.empty?

    ary.each do |evt|
      @log.debug "changed #{evt.path}"
      next unless test ?f, evt.path
      next if evt.path =~ ::Webby.exclude
      Resource.new evt.path
    end

    @builder.run :load_files => false
  rescue => err
    @log.error err
  end

  # call-seq:
  #    run
  #
  # Starts the DirectoryWatcher running and waits till the user presses
  # Ctrl-C to stop the watcher thread.
  #
  def run
    @log.info 'starting autobuild (Ctrl-C to stop)'

    Signal.trap('INT') {@watcher.stop}

    @watcher.start
    @watcher.join
  end

end  # class AutoBuilder
end  # module Webby

# EOF
