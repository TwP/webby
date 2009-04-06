require 'optparse'
require 'rake'

module Webby::Apps

class Main

  # Create a new instance of Main, and run the +webby+ application given the
  # command line _args_.
  #
  def self.run( args )
    self.new.run args
  end

  attr_reader :cmd_line_options

  # Create a new Main webby object for building websites.
  #
  def initialize
    @stdout = $stdout
    @cmd_line_options = {}
    @command = %w[rake]
  end

  # Runs the main webby application. The command line arguments are passed
  # in to this method as an array of strings. The command line arguments are
  # parsed to figure out which rake task to invoke.
  #
  def run( args )
    args = args.dup

    parse args
    init args
    self.__send__(*@command)
  end

  # Parse the command line _args_ for options and commands to invoke.
  #
  def parse( args )
    opts = OptionParser.new
    opts.banner = 'Usage: webby [options] target [target args]'

    opts.separator ''

    desired_opts = %[--describe --prereqs --tasks --trace]
    app.standard_rake_options.each do |options|
      next unless desired_opts.include?(options.first)
      opts.on(*options)
    end
    opts.on('-o', '--options [PATTERN]',
            'Show configuration options (matching optional pattern), then exit.') { |value|
      @command = [:show_options, value]
    }

    opts.separator ''
    opts.separator 'autobuild options:'

    opts.on('--web-server', 'Start a local web server') {
      cmd_line_options[:use_web_server] = true
    }
    opts.on('--no-web-server', 'Do not start a local web server') {
      cmd_line_options[:use_web_server] = false
    }

    opts.separator ''
    opts.separator 'common options:'

    opts.on_tail( '-h', '--help', 'show this message' ) do
      @stdout.puts opts
      exit
    end
    opts.on_tail( '--version', 'show version' ) do
      @stdout.puts "Webby #{::Webby::VERSION}"
      exit
    end

    opts.parse! args

    ARGV.replace Array(args.shift)
    args.delete_if do |arg|
      if %r/^[A-Z_]+=/ =~ arg
        ARGV << arg
        next true
      end
      false
    end

    args
  end

  # Initialize the Rake application object and load the core rake tasks, the
  # site specific rake tasks, and the site specific ruby code. Any extra
  # command line arguments are converted into a page name and directory that
  # might get created (depending upon the task invoked).
  #
  def init( args )
    # Make sure we're in a folder with a Sitefile
    options = app.standard_rake_options
    [['--rakefile', 'Sitefile'],
     ['--no-search', nil],
     ['--silent', nil]].each {|opt, value| options.assoc(opt).last.call(value)}

    unless app.have_rakefile
      raise RuntimeError, "Sitefile not found"
    end

    import_default_tasks
    import_website_tasks
    require_lib_files
    capture_command_line_args(args)
    args
  end

  # Execute the rake command.
  #
  def rake
    app.init 'webby'
    app.load_rakefile
    load_command_line_options
    app.top_level
  end

  # Print the available configuration options.
  #
  def show_options( attribute = nil )
    app.init 'webby'
    app.load_rakefile

    desc = <<-__
      The following options can be used to control Webby functionality.
      Options are configured in the 'Sitefile'. A few examples are shown below:
      |
      |   SITE.create_mode = 'directory'
      |   SITE.base        = 'http://www.example.com'
      |   SITE.uv.theme    = 'twilight'
      |
      =======< OPTIONS >=======
      |
    __
    
    @stdout.puts desc.gutter!
    help = Loquacious.help_for(
      :webby, :io => @stdout, :colorize => ENV.key?('TERM')
    )
    help.show attribute, :values => true
    @stdout.puts
  end

  # Return the Rake application object.
  #
  def app
    Rake.application
  end

  # Returns the options hash from the Rake application object.
  #
  def options
    app.options
  end

  # Search for the "Sitefile" starting in the current directory and working
  # upwards through the filesystem until the root of the filesystem is
  # reached. If a "Sitefile" is not found, a RuntimeError is raised.
  #
  def find_sitefile
    here = Dir.pwd
    while ! app.have_rakefile
      Dir.chdir("..")
      if Dir.pwd == here || options.nosearch
        fail "No Sitefile found"
      end
      here = Dir.pwd
    end
  end

  def import_default_tasks
    Dir.glob(::Webby.libpath(%w[webby tasks *.rake])).sort.each {|fn| import fn}
  end

  def import_website_tasks
    Dir.glob(::File.join(%w[tasks *.rake])).sort.each {|fn| import fn}
  end

  def require_lib_files
    Dir.glob(::File.join(%w[lib ** *.rb])).sort.each {|fn| require fn}
  end

  def capture_command_line_args(args)
    args = OpenStruct.new(
      :raw  => args,
      :rake => ARGV.dup
    )

    if args.raw.size > 1
      ::Webby.deprecated "multiple arguments used for page title",
                         "please quote the page title"
    end

    dashed = args.raw.join('-').downcase
    spaced = args.raw.join(' ')
    dir = ::File.dirname(dashed)

    args.dir   = ('.' == dir ? '' : dir)
    args.slug  = ::Webby::Resources.basename(dashed).to_url
    args.title = ::Webby::Resources.basename(spaced).titlecase

    # page should be dir/slug without leading /
    args.page  = ::File.join(args.dir, args.slug).gsub(/^\//, '')

    ext = ::File.extname(dashed)
    args.page << ext unless ext.empty?

    ::Webby.site.args = args
    Object.const_set(:SITE, Webby.site)
    args
  end

  # Load options from the command line into the ::Webby.site struct
  #
  def load_command_line_options
    cmd_line_options.each do |key, value|
      ::Webby.site.__send__("#{key}=", value)
    end
  end

end  # class Main
end  # module Webby::Apps

# EOF
