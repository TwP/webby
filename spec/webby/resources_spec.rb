

require File.expand_path(
    File.join(File.dirname(__FILE__), %w[.. spec_helper]))

# --------------------------------------------------------------------------
describe Webby::Resources do
  before :each do
    Webby::Resources.clear
  end

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

  # ------------------------------------------------------------------------
  describe "#new" do
    before :each do
      layout = Webby::Resources::Layout.
               new(Webby.datapath(%w[site layouts default.txt]))
      Webby::Resources.stub!(:find_layout).and_return(layout)
    end

    it "creates multiple pages for files with multiple YAML sections" do
      pages = Webby::Resources.pages

      fn = File.join %w[content photos.txt]
      Webby::Resources.new(fn)

      ary = pages.find(:all, :in_directory => 'photos')
      ary.map {|page| page.title}.should == [
        'First Photo', 'Second Photo', 'Third Photo'
      ]
    end
  end

end

# EOF
