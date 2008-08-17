require 'main'
require 'rake'

module Webby::Apps

Main = ::Main.create {
  author ::Webby::Apps.author
  version ::Webby::VERSION

  description 'TODO: add a description'

  examples 'TODO: add some examples'

  argument('target') {
    desc 'the task to exectue'
    optional
    attr
  }

  option('describe', 'D') {
    argument :optional
    synopsis '--describe=[PATTERN], -D'
    desc 'describe the tasks (mathcing optional PATTERN)'
  }

  option('prereqs', 'P') {
    desc 'display the tasks and dependencies, then exit'
  }

  option('tasks', 'T') {
    argument :optional
    synopsis '--tasks=[PATTERN], -T'
    desc 'display the tasks (mathcing optional PATTERN)'
  }

  option('trace', 't') {
    desc 'turn on invoke/execute tracing, enable full backtrace'
  }

  def run
    app = Rake.application

    # configure the rake application
    %w[describe prereqs tasks trace].each do |opt|
      p = params[opt]
      app.do_option("--#{opt}", (true == p.value ? nil : p.value)) if p.given?
    end
    app.do_option('--rakefile', 'Sitefile')
    app.do_option('--nosearch', nil)
    app.do_option('--silent', nil)

    # Make sure we're in a folder with a Sitefile
    unless app.have_rakefile
      raise RuntimeError, "Sitefile not found"
    end

    # do the webby stuff
    import_default_tasks
    import_website_tasks
    require_lib_files
    capture_command_line_args([argv])

    # the only thing we want to send to rake is the target to execute
    ARGV.replace Array(target)

    # run rake
    app.init 'webby'
    app.load_rakefile
    app.top_level
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
    args = OpenStruct.new(:raw => args)

    if args.raw.size > 1
      ::Webby.deprecated "multiple arguments used for page title",
                         "please quote the page title"
    end

    args.dir   = ::Webby::Resources::File.dirname(args.raw.join('-').downcase)
    args.slug  = ::Webby::Resources::File.basename(args.raw.join('-').downcase).to_url
    args.title = ::Webby::Resources::File.basename(args.raw.join(' ')).titlecase

    # page should be dir/slug without leading /
    args.page  = ::File.join(args.dir, args.slug).gsub(/^\//, '')

    ::Webby.site.args = args
    Object.const_set(:SITE, Webby.site)
    args
  end

}

# The Webby::Main class contains all the functionality needed by the +webby+
# command line application.
#
class OldMain

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

end
end  # module Webby::Apps

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

  # Provide standard execption handling for the given block.
  def standard_exception_handling
    begin
      yield
    rescue SystemExit => ex
      # Exit silently with current status
      exit(ex.status)
    rescue SystemExit, GetoptLong::InvalidOption => ex
      # Exit silently
      exit(1)
    rescue Exception => ex
      # Exit with error message
      $stderr.puts "webby aborted!"
      $stderr.puts ex.message
      if options.trace
        $stderr.puts ex.backtrace.join("\n")
      else
        $stderr.puts ex.backtrace.find {|str| str =~ /#{@rakefile}/ } || ""
        $stderr.puts "(See full trace by running task with --trace)"
      end
      exit(1)
    end
  end
end  # class Rake::Application
# :startdoc:

# EOF
