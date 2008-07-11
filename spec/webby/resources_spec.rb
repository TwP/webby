

require ::File.join(::File.dirname(__FILE__), %w[.. spec_helper])

# ---------------------------------------------------------------------------
describe Webby::Resources do
  it "should raise a useful error if there are no layouts" do
    layouts = mock("Layouts")
    Webby::Resources.stub!(:layouts).and_return(layouts)
    layouts.should_receive(:find).and_raise RuntimeError

    lambda do
      Webby::Resources.find_layout("default")
    end.should raise_error(Webby::Error, 'could not find layout "default"')
    
  end
end
