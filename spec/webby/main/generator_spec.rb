
require ::File.expand_path(
    ::File.join(::File.dirname(__FILE__), %w[.. .. spec_helper]))
require 'stringio'

describe Webby::Main::Generator do

  before :each do
    @generator = Webby::Main::Generator.new
  end

  it "should return a list of available templates" do
    ary = %w[presentation webby website].map {|t| Webby.path('examples', t)}
    @generator.templates.should == ary
  end

  it "should pretend to create a site" do
    @generator.parse %w[-p website foo]
    @generator.pretend?.should == true

    @generator = Webby::Main::Generator.new
    @generator.parse %w[website foo]
    @generator.pretend?.should == false

    @generator = Webby::Main::Generator.new
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
        "content/css/blueprint/compressed",
        "content/css/blueprint/lib",
        "content/css/blueprint/plugins",
        "content/css/blueprint/plugins/buttons",
        "content/css/blueprint/plugins/buttons/icons",
        "content/css/blueprint/plugins/css-classes",
        "content/css/blueprint/plugins/fancy-type",
        "layouts",
        "lib",
        "tasks",
        "templates",
        "templates/blog"
    ]
    h["content"].should == %w[content/index.txt]
    h["layouts"].should == %w[layouts/default.rhtml]
  end

  describe "when parsing command line arguments" do

    before :each do
      @strio = StringIO.new
      @generator = Webby::Main::Generator.new
      @generator.instance_variable_set(:@stdout, @strio)
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

    it "should exit if a site is not specified"
    it "should exit if an unknown template is given"
  end
end

# EOF
