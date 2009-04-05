
require File.expand_path(
    File.join(File.dirname(__FILE__), %w[.. .. spec_helper]))

# -------------------------------------------------------------------------
describe Webby::Resources::Resource do

  before :each do
    layout = Webby::Resources::Layout.
             new(Webby.datapath(%w[site layouts default.txt]))
    Webby::Resources.stub!(:find_layout).and_return(layout)

    @filename = File.join %w[content index.txt]
    @resource = Webby::Resources::Resource.new(@filename)
  end

  it 'does not parse meta-data by default' do
    @resource._meta_data.should be_empty
  end

  it 'provides the path to the file' do
    @resource.path.should == @filename
  end

  it 'returns the bare filename' do
    @resource.name.should == 'index'

    resource = Webby::Resources::Resource.
                   new(File.join(%w[content tumblog rss.txt]))
    resource.name.should == 'rss'
  end

  it 'returns the path-based extension' do
    @resource.ext.should == 'txt'
  end

  it 'computes the directory of the file with the content folder removed' do
    @resource.dir.should == ''

    resource = Webby::Resources::Resource.
                   new(File.join(%w[content tumblog index.txt]))
    resource.dir.should == 'tumblog'
  end

  it 'returns the modification time of the file' do
    @resource.mtime.should be_instance_of(Time)
  end

  it 'determines equality from the full path' do
    a = Webby::Resources::Resource.new(File.join(%w[content tumblog index.txt]))
    b = Webby::Resources::Resource.new(File.join(%w[content tumblog rss.txt]))
    c = Webby::Resources::Resource.new(File.join(%w[content tumblog index.txt]))

    (a == b).should == false
    (a == c).should == true
    (b == c).should == false
    (a == nil).should == false
    (a == a.path).should == false

    b['filename'] = 'index'
    b._reset
    b.destination.should == a.destination
    (a == b).should == false
  end

  it 'compares two resources by path' do
    a = Webby::Resources::Resource.new(File.join(%w[content tumblog index.txt]))
    b = Webby::Resources::Resource.new(File.join(%w[content tumblog rss.txt]))
    c = Webby::Resources::Resource.new(File.join(%w[content tumblog index.txt]))

    (a <=> b).should == -1
    (b <=> a).should ==  1
    (a <=> c).should ==  0
    (a <=> a).should ==  0
    (a <=> nil).should be_nil
    (a <=> a.path).should be_nil
  end

  it 'can alter meta-data' do
    @resource['title'].should be_nil
    @resource[:title] = 'Home Page'

    @resource['title'].should == 'Home Page'
    @resource[:title].should == 'Home Page'
    @resource[:title].should equal(@resource['title'])
  end

  it 'overrides the dirty state based on the meta-data value' do
    @resource['dirty'] = true
    @resource.dirty?.should == true

    @resource['dirty'] = false
    @resource.dirty?.should == false
  end

  it 'reads the contents of the file' do
    str = @resource._read
    str.split($/).first.should == "p(title). <%= @page.title %>"
  end

  it 'repleces the meta-data hash when reset' do
    @resource._meta_data.should be_empty
    oid = @resource._meta_data.object_id

    @resource._reset('foo' => 'bar')
    @resource._meta_data.should_not be_empty
    @resource._meta_data.object_id.should == oid
    @resource._meta_data['foo'].should == 'bar'
  end

  # -----------------------------------------------------------------------
  describe '.filename' do
    it 'uses the filename from the meta-data if present' do
      @resource['filename'] = 'bozo'
      @resource.filename.should == 'bozo'
    end

    it "uses the file's filename as a last ditch effort" do
      @resource.filename.should == 'index'
    end
  end

  # -----------------------------------------------------------------------
  describe '.extension' do
    it 'uses the extension from the meta-data if present' do
      @resource['extension'] = 'foo'
      @resource.extension.should == 'foo'
    end

    it "uses the file's extension as a last ditch effort" do
      @resource.extension.should == 'txt'
    end
  end

  # -----------------------------------------------------------------------
  describe '.directory' do
    it 'uses the directory from the meta-data if present' do
      @resource['directory'] = 'foo'
      @resource.directory.should == 'foo'
    end

    it "uses the file's directory as a last ditch effort" do
      @resource.directory.should == ''
    end
  end

  # -----------------------------------------------------------------------
  describe '.url' do
    it 'computes the url from the filename and directory' do
      @resource.url.should == '/index.txt'
    end

    it 'caches the url' do
      @resource.url.should == '/index.txt'

      @resource['directory'] = 'foo/bar/baz'
      @resource.url.should == '/index.txt'
    end

    it 'clears the cached url on reset' do
      @resource.url.should == '/index.txt'

      @resource['directory'] = 'foo/bar/baz'
      @resource.url.should == '/index.txt'

      @resource._reset
      @resource.url.should == '/foo/bar/baz/index.txt'
    end
  end

  # -----------------------------------------------------------------------
  describe '.destination' do
    it 'computes the destination from the filename and directory' do
      @resource.destination.should == 'output/index.txt'
    end

    it 'caches the destination' do
      @resource.destination.should == 'output/index.txt'

      @resource['directory'] = 'foo/bar/baz'
      @resource.destination.should == 'output/index.txt'
    end

    it 'clears the cached destination on reset' do
      @resource.destination.should == 'output/index.txt'

      @resource['directory'] = 'foo/bar/baz'
      @resource.destination.should == 'output/index.txt'

      @resource._reset
      @resource.destination.should == 'output/foo/bar/baz/index.txt'
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

    it 'returns false if everything is up to date' do
      dest = @resource.destination
      FileUtils.touch dest

      @resource.dirty?.should == false
    end
  end

end  # describe Webby::Resources::Resource

# EOF
