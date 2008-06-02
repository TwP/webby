
require ::File.expand_path(
    ::File.join(::File.dirname(__FILE__), %w[.. .. spec_helper]))

# ---------------------------------------------------------------------------
describe Webby::Helpers::CaptureHelper do
  CFN = ::File.expand_path(::File.join(::File.dirname(__FILE__), '..', '..', 'capture_for_yaml.txt'))
  CLINES = [
    "--- ",
    "filter: ",
    "  - erb ",
    "--- ",
    "Hello world!",
    "<% content_for :sidebar do %>",
    "I'm sidebar content.",
    "<% end %>"
  ]

  before :all do
    ::File.open(CFN,'w') {|fd| fd.write CLINES.join("\n") }
  end

  before :each do
    @renderman = Webby::Renderer.new(
                 Webby::Resources::Page.new(CFN))
    @page_content = @renderman.render_page
  end

  after :all do
    ::FileUtils.rm_f(CFN)
  end

  it 'should not "leak" any content to containing page' do
    @page_content.should_not be_nil
    @page_content.should eql("Hello world!\n")
  end

  it "should return the stored content for the given key" do
    @renderman.content_for(:sidebar).should_not be_nil
    @renderman.content_for(:sidebar).should eql("\nI'm sidebar content.\n") # Note: Leading newline
  end

  it "should report if content is associated with a given key" do
    @renderman.content_for?(:sidebar).should == true
    @renderman.content_for?(:header).should == false
  end

  it "should clear content associated with a given key" do
    @renderman.content_for?(:sidebar).should == true
    @renderman.delete_content_for(:sidebar)
    @renderman.content_for?(:sidebar).should == false
  end

end

# EOF
