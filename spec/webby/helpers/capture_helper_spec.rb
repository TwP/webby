
require ::File.join(::File.dirname(__FILE__), %w[.. .. spec_helper])

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

  before do
    ::File.open(CFN,'w') {|fd| fd.write CLINES.join("\n") }
    @page = Webby::Resources::Page.new(CFN)
    @renderman = Webby::Renderer.new(@page)
    @page_content = @page.render( @renderman )
  end
  
  after do 
    ::FileUtils.rm_f(CFN)
  end


  it 'should not "leak" any content to containing page' do
    @page_content.should_not be_nil
    @page_content.should eql("Hello world!\n")
  end
  
  it "should create an instance variable containing the nested content" do
    @renderman.instance_variable_get("@content_for_sidebar").should_not be_nil
    @renderman.instance_variable_get("@content_for_sidebar").should eql("\nI'm sidebar content.\n") # Note: Leading newline
  end

end  # describe Webby::Resources::File

# EOF
