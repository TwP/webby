
require File.expand_path(
    File.join(File.dirname(__FILE__), %w[.. .. spec_helper]))

# -------------------------------------------------------------------------
describe Webby::Resources::Page do
  before :each do
    layout = Webby::Resources::Layout.
             new(Webby.datapath(%w[site layouts default.txt]))
    Webby::Resources.stub!(:find_layout).and_return(layout)

    @filename = File.join %w[content index.txt]
    @page = Webby::Resources::Page.new(@filename)
  end

  it 'parses meta-data on initialization' do
    h = @page._meta_data

    h.should_not be_empty
    h['title'].should == 'Home Page'
    h['filter'].should == ['erb', 'textile']
    h['layout'].should == 'default'
  end

  it 'can be given a hash of meta-data on initialization' do
    page = Webby::Resources::Page.new(
      @filename,
      'title' => 'Not Your Average Title'
    )

    h = page._meta_data
    h.should_not be_empty
    h['title'].should == 'Not Your Average Title'
    h['layout'].should == 'default'
    h['created_at'].should be_nil
    h['filter'].should be_nil
  end

  it 'reads the contents of the file' do
    str = @page._read
    str.split($/).first.should == "p(title). <%= @page.title %>"
  end

  # -----------------------------------------------------------------------
  describe '.url' do
    before :each do
      @filename = File.join %w[content tumblog rss.txt]
      @page = Webby::Resources::Page.new(@filename)
    end

    it 'computes the url from the destination' do
      @page.url.should == '/tumblog/rss.xml'
    end

    it "uses only the directory name for 'index' files" do
      filename = File.join %w[content tumblog index.txt]
      resource = Webby::Resources::Page.new(filename)
      resource.url.should == '/tumblog/'
    end

    it "avoids adding a double trailing slash on the end" do
      filename = File.join %w[content index.txt]
      resource = Webby::Resources::Page.new(filename)
      resource.url.should == '/'
    end
  end

  # -----------------------------------------------------------------------
  describe '.extension' do
    it 'uses the extension from the meta-data if present' do
      @page['extension'] = 'foo'
      @page.extension.should == 'foo'
    end

    it "uses the layout's extension if a layout is present" do
      @page.extension.should == 'html'
    end

    it "uses the file's extension as a last ditch effort" do
      @page._meta_data.delete('layout')
      @page.extension.should == 'txt'
    end
  end

  # -----------------------------------------------------------------------
  describe '.dirty?' do
    it 'overrides the dirty state based on the meta-data value' do
      @page['dirty'] = true
      @page.dirty?.should == true

      @page['dirty'] = false
      @page.dirty?.should == false
    end

    it 'returns true if the output file is missing' do
      @page.dirty?.should == true
    end

    it 'returns true if the layout is dirty' do
      dest = @page.destination
      FileUtils.touch dest

      @page.dirty?.should == true
    end

    it 'returns false if everything is up to date' do
      dest = @page.destination
      FileUtils.touch dest
      FileUtils.touch ::Webby.cairn

      @page.dirty?.should == false
    end
  end

end  # describe Webby::Resources::Page

# EOF
