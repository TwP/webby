
require ::File.expand_path(
    ::File.join(::File.dirname(__FILE__), %w[.. .. spec_helper]))
require 'stringio'

describe Webby::Apps::Generator do

  before :each do
    @generator = Webby::Apps::Generator.new
  end

  it "should return a list of available templates" do
    ary = %w[blog presentation tumblog webby website].map {|t| Webby.path('examples', t)}
    @generator.templates.should == ary
  end

  it "should pretend to create a site" do
    @generator.parse %w[-p website foo]
    @generator.pretend?.should == true

    @generator = Webby::Apps::Generator.new
    @generator.parse %w[website foo]
    @generator.pretend?.should == false

    @generator = Webby::Apps::Generator.new
    @generator.parse %w[--pretend website foo]
    @generator.pretend?.should == true
  end

  it "should return a list of all the site files from the template" do
    @generator.parse %w[website foo]

    h = @generator.site_files
    h.keys.sort.should == [
        "",
        "content",
        "content/css",
        "content/css/blueprint",
        "content/css/blueprint/plugins",
        "content/css/blueprint/plugins/buttons",
        "content/css/blueprint/plugins/buttons/icons",
        "content/css/blueprint/plugins/fancy-type",
        "content/css/blueprint/plugins/link-icons",
        "content/css/blueprint/plugins/link-icons/icons",
        "content/css/blueprint/plugins/rtl",
        "content/css/blueprint/src",
        "layouts",
        "lib",
        "templates"
    ]
    h["content"].should == %w[content/index.txt]
    h["layouts"].should == %w[layouts/default.txt]
  end

  it "should return a list of all the blog files from the template" do
    @generator.parse %w[blog foo]

    h = @generator.site_files
    h.keys.sort.should == [
      "",
      "content",
      "content/css",
      "content/css/blueprint",
      "content/css/blueprint/plugins",
      "content/css/blueprint/plugins/buttons",
      "content/css/blueprint/plugins/buttons/icons",
      "content/css/blueprint/plugins/fancy-type",
      "content/css/blueprint/plugins/link-icons",
      "content/css/blueprint/plugins/link-icons/icons",
      "content/css/blueprint/plugins/rtl",
      "content/css/blueprint/src",
      "layouts",
      "tasks",
      "templates",
      "templates/blog"
    ]
    h["layouts"].should == %w[layouts/default.txt]
    h["tasks"].should == %w[tasks/blog.rake]
    h["templates"].should == %w[templates/atom_feed.erb]
    h["templates/blog"].should == [
      "templates/blog/year.erb",
      "templates/blog/post.erb",
      "templates/blog/month.erb"
    ]
  end

  describe "when parsing command line arguments" do

    before :each do
      @strio = StringIO.new
      ::Logging::Logger['Webby::Journal'].appenders =
          ::Logging::Appenders::IO.new('test', @strio)
      @generator = Webby::Apps::Generator.new(@strio)

      class << @strio
        def to_s
          seek 0
          str = read
          truncate 0
          return str
        end
      end
    end

    it "should force the overwriting of files on collision" do
      @generator.options[:collision].should be_nil
      @generator.parse %w[-f website foo]
      @generator.options[:collision].should == :force
    end

    it "should skip files on collision" do
      @generator.options[:collision].should be_nil
      @generator.parse %w[-s website foo]
      @generator.options[:collision].should == :skip
    end

    it "should update only the rake files in the tasks folder" do
      @generator.options[:update].should be_nil
      @generator.parse %w[-u website foo]
      @generator.options[:update].should == true
    end

    it "should pretend to generate / alter files" do
      @generator.options[:pretend].should be_nil
      @generator.parse %w[-p website foo]
      @generator.options[:pretend].should == true
    end

    it "should exit if a site is not specified" do
      # we need to force an error by changing directories back to the top
      # level so we no longer have a Sitefile in the current directory
      Dir.chdir @pwd

      lambda{@generator.parse %w[website]}.
          should raise_error(SystemExit, 'exit')
      @strio.to_s.split("\n").first.
          should == 'Usage: webby-gen [options] template site'
    end

    it "should exit if an unknown template is given" do
      lambda{@generator.parse %w[foo bar]}.
          should raise_error(SystemExit, 'exit')
      @strio.to_s.split("\n").last.
          should == "    Could not find template 'foo'"
    end
  end
end

# EOF
