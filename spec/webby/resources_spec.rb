

require File.expand_path(
    File.join(File.dirname(__FILE__), %w[.. spec_helper]))

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

  it "should return the directory name for a file" do
    Webby::Resources.dirname('content').should == './'
    Webby::Resources.dirname('layouts').should == './'

    Webby::Resources.dirname('content/index.txt').should == ''
    Webby::Resources.dirname('layouts/default.txt').should == ''

    Webby::Resources.dirname('content/tumblog/index.txt').should == 'tumblog'
    Webby::Resources.dirname('layouts/tumblog/post.txt').should == 'tumblog'

    Webby::Resources.dirname('output/tumblog/index.html').should == 'output/tumblog'
    Webby::Resources.dirname('templates/tumblog/post.erb').should == 'templates/tumblog'
  end

  it "should normalize the path for a filename" do
    Webby::Resources.path('content').should == 'content'
    Webby::Resources.path('/content').should == 'content'
    Webby::Resources.path('./content').should == 'content'

    Webby::Resources.path('./').should == ''
    Webby::Resources.path('/').should == ''
    Webby::Resources.path('').should == ''
  end
end
