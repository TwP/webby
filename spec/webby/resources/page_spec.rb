
require File.expand_path(
    File.join(File.dirname(__FILE__), %w[.. .. spec_helper]))

# -------------------------------------------------------------------------
describe Webby::Resources::Page do
  before :each do
    layout = Webby::Resources::Layout.
             new(Webby.datapath %w[layouts default.txt])
    Webby::Resources.stub!(:find_layout).and_return(layout)
  end

  before :each do
    @filename = File.join %w[content index.txt]
    @resource = Webby::Resources::Page.new(@filename)
  end

  it 'parses meta-data on initialization' do
    h = @resource._meta_data

    h.should_not be_empty
    h['title'].should == 'Home Page'
    h['filter'].should == ['erb', 'textile']
  end

  # -----------------------------------------------------------------------
  describe '.url' do
    before :each do
      @filename = File.join %w[content tumblog rss.txt]
      @resource = Webby::Resources::Page.new(@filename)
    end

    it 'computes the url from the destination' do
      @resource.url.should == '/tumblog/rss.xml'
    end

    it "uses only the directory name for 'index' files" do
      filename = File.join %w[content tumblog index.txt]
      resource = Webby::Resources::Page.new(filename)
      resource.url.should == '/tumblog'
    end

    it 'adds the page number to the url' do
      filename = File.join %w[content tumblog index.txt]
      resource = Webby::Resources::Page.new(filename)
      resource.number = 42
      resource.url.should == '/tumblog/index42.html'
    end
  end

  # -----------------------------------------------------------------------
  describe '.extension' do
    it 'uses the extension from the meta-data if present' do
      @resource['extension'] = 'foo'
      @resource.extension.should == 'foo'
    end

    it "uses the layout's extension if a layout is present" do
      @resource.extension.should == 'html'
    end

    it "uses the file's extension as a last ditch effort" do
      @resource._meta_data.delete('layout')
      @resource.extension.should == 'txt'
    end
  end

  # -----------------------------------------------------------------------
  describe '.destination' do
    it 'uses the destination from the meta-data if present' do
      @resource['destination'] = 'foo/bar/baz'
      @resource.destination.should == 'output/foo/bar/baz.html'
    end

    it 'computes the destination from the filename and dir' do
      @resource.destination.should == 'output/index.html'
    end

    it 'caches the destination' do
      @resource.destination.should == 'output/index.html'

      @resource['destination'] = 'foo/bar/baz'
      @resource.destination.should == 'output/index.html'
    end

    it 'incorporates the page number into the destination' do
      @resource.number = 42
      @resource.destination.should == 'output/index42.html'

      @resource.number = 2
      @resource.destination.should == 'output/index2.html'
    end
  end

  # -----------------------------------------------------------------------
  describe '.dirty?' do
    it 'overrides the dirty state based on the meta-data value' do
      @resource['dirty'] = true
      @resource.dirty?.should == true

      @resource['dirty'] = false
      @resource.dirty?.should == false
    end

    it 'returns true if the output file is missing' do
      @resource.dirty?.should == true
    end

    it 'returns true if the layout is dirty' do
      dest = @resource.destination
      FileUtils.mkdir_p File.dirname(dest)
      FileUtils.touch dest

      @resource.dirty?.should == true
    end

    it 'returns false if everything is up to date' do
      dest = @resource.destination
      FileUtils.mkdir_p File.dirname(dest)
      FileUtils.touch dest
      FileUtils.touch 'output/.cairn'

      @resource.dirty?.should == false
    end
  end

end  # describe Webby::Resources::Resource

# EOF
