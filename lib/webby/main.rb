require 'optparse'
require 'rake'

module Webby

# The Webby::Main class contains all the functionality needed by the +webby+
# command line application.
#
class Main

  # Create a new instance of Main, and run the +webby+ application given the
  # command line _args_.
  #
  def self.run( args )
    self.new.run args
  end

  # Create a new Main webby object for building websites.
  #
  def initialize
    @stdout = $stdout
  end

  def run( args )
    if 'gen' == args[0]
      args.shift
      gen = Generator.new
      gen.run args
    else
      parse args
      init args
      rake
    end
  end

  def parse( args )
    opts = OptionParser.new
    opts.banner = 'Usage: webby [options] target [target args]'

    opts.separator ''
    opts.on('-D', '--describe [PATTERN]', 'describe the tasks (matching optional PATTERN), then exit') {|pattern| app.do_option('--describe', pattern)}
    opts.on('-P', '--prereqs', 'display the tasks and dependencies, then exit') {app.do_option('--prereqs', nil)}
    opts.on('-T', '--tasks [PATTERN]', 'display the tasks (matching optional PATTERN) with descriptions, then exit') {|pattern| app.do_option('--tasks', pattern)}
    opts.on('-t', '--trace', 'turn on invoke/execute tracing, enable full backtrace') {app.do_option('--trace', nil)}

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

    opts.parse %[--help] if args.empty?
    opts.parse! args

    ARGV.replace Array(args.shift)
    args
  end

  def init( args )
    # Make sure we're in a folder with a Sitefile
    app.do_option('--rakefile', 'Sitefile')
    app.do_option('--nosearch', nil)

    if ! app.have_rakefile
      @stdout.puts "    Sitefile not found"
      abort
    end

    # Load the website tasks from the tasks folder
    Dir.glob(::File.join(%w[tasks *.rake])).sort.each {|fn| import fn}

    # Load all the ruby files in the lib folder
    Dir.glob(::File.join(%w[lib ** *.rb])).sort.each {|fn| require fn}

    # Capture the command line args for use by the Rake tasks
    args = Webby.site.args = OpenStruct.new(
      :raw => args,
      :page => args.join('-').downcase
    )
    args.dir = ::File.dirname(args.page)
    args.slug = ::File.basename(args.page)
    args.title = ::File.basename(args.raw.join(' ')).titlecase

    Object.const_set(:SITE, Webby.site)
  end

  def rake
    app.init 'webby'
    app.load_rakefile
    app.top_level
  end

  def app
    Rake.application
  end

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

end  # class Main
end  # module Webby

# :stopdoc:
# Monkey patches so that rake displays the correct application name in the
# help messages.
#
class Rake::Application
  def display_prerequisites
    tasks.each do |t|
      puts "#{name} #{t.name}"
      t.prerequisites.each { |pre| puts "    #{pre}" }
    end
  end

  def display_tasks_and_comments
    displayable_tasks = tasks.select { |t|
      t.comment && t.name =~ options.show_task_pattern
    }
    if options.full_description
      displayable_tasks.each do |t|
        puts "#{name} #{t.name_with_args}"
        t.full_comment.split("\n").each do |line|
          puts "    #{line}"
        end
        puts
      end
    else
      width = displayable_tasks.collect { |t| t.name_with_args.length }.max || 10
      max_column = 80 - name.size - width - 7
      displayable_tasks.each do |t|
        printf "#{name} %-#{width}s  # %s\n",
          t.name_with_args, truncate(t.comment, max_column)
      end
    end
  end
end
# :startdoc:

# EOF
