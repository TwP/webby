require 'directory_watcher'
require 'launchy'
require 'webrick'

module Webby

# The AutoBuilder class is used to monitor the content and layouts folders
# and to compile the resource files only when they are modified. If a
# layout is modified, then all resources that depend upon the layout are
# compiled.
#
class AutoBuilder

  # TODO: hit Ctrl-C once to rebuild everything, and hit it twice to stop the autobuild loop

  # call-seq:
  #    AutoBuilder.run
  #
  # Creates a new AutoBuilder and sets it running. This method will only
  # return when the user presses Ctrl-C.
  #
  def self.run
    self.new.run
  end

  attr_reader :logger

  # call-seq:
  #    AutoBuilder.new
  #
  # Create a new AutoBuilder class.
  #
  def initialize
    @logger = Logging::Logger[self]

    @builder = Builder.new
    ::Webby.load_files

    @watcher = DirectoryWatcher.new '.', :interval => 2
    @watcher.add_observer self

    glob = []
    glob << File.join(::Webby.site.layout_dir, '**', '*')
    glob << File.join(::Webby.site.content_dir, '**', '*')
    @watcher.glob = glob

    @web_server = ::Webby.site.use_web_server ? WebServer.new : nil
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
      logger.debug "changed #{evt.path}"
      next unless test ?f, evt.path
      next if evt.path =~ ::Webby.exclude
      Resources.new evt.path
    end

    logger.info 'running the build'
    @builder.run :load_files => false, :verbose => false
  rescue => err
    logger.error err
  end

  # call-seq:
  #    run
  #
  # Starts the DirectoryWatcher running and waits till the user presses
  # Ctrl-C to stop the watcher thread.
  #
  def run
    logger.info 'starting autobuild (Ctrl-C to stop)'

    Signal.trap('INT') {
      @watcher.stop
      @web_server.stop if @web_server
    }

    @watcher.start
    if @web_server
      @web_server.start
      sleep 0.25
      Launchy.open("http://localhost:#{::Webby.site.web_port}")
    end

    @watcher.join
    @web_server.join if @web_server
  end

  # Wrapper class around the webrick web server.
  #
  class WebServer

    # Create a new webrick server configured to serve pages from the output
    # directory. Output will be directed to /dev/null.
    #
    def initialize
      logger = WEBrick::Log.new(Kernel::DEV_NULL, WEBrick::Log::DEBUG)
      access_log = [[ logger, WEBrick::AccessLog::COMBINED_LOG_FORMAT ]]

      @thread = nil
      @running = false
      @server = WEBrick::HTTPServer.new(
        :BindAddress   => 'localhost',
        :Port          => ::Webby.site.web_port,
        :DocumentRoot  => ::Webby.site.output_dir,
        :FancyIndexing => true,
        :Logger        => logger,
        :AccessLog     => access_log
      )
    end

    # Returns +true+ if the server is running.
    #
    def running?
      @running
    end

    # Start the webrick server running in a separate thread (so we don't
    # block forever).
    #
    def start
      return if running?
      @running = true
      @thread = Thread.new {@server.start}
    end

    # Stop the webrick server.
    #
    def stop
      return if not running?
      @running = false
      @server.shutdown
    end

    # Join on the webserver thread.
    #
    def join
      return if not running?
      @thread.join
    end

  end  # class WebServer

end  # class AutoBuilder
end  # module Webby

# EOF
