
require ::File.expand_path(
    ::File.join(::File.dirname(__FILE__), %w[.. spec_helper]))

describe Webby::Generator do

  before :each do
    @generator = Webby::Generator.new
  end

  it "should parse command line arguments"
  it "should return a list of available templates" do
    ary = %w[presentation webby website].map {|t| Webby.path('examples', t)}
    @generator.templates.should == ary
  end

  it "should pretend to create a site" do
    @generator.parse %w[-p website foo]
    @generator.pretend?.should == true

    @generator = Webby::Generator.new
    @generator.parse %w[website foo]
    @generator.pretend?.should == false

    @generator = Webby::Generator.new
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
end

# EOF
