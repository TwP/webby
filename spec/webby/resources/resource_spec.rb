
require File.expand_path(
    File.join(File.dirname(__FILE__), %w[.. .. spec_helper]))

# -------------------------------------------------------------------------
describe Webby::Resources::Resource do

  before :each do
    @filename = File.join %w[content index.txt]
    @resource = Webby::Resources::Resource.new(@filename)
  end

  it 'does not parse meta-data by default' do
    @resource._meta_data.should be_empty
  end

  it 'does not compute the destination by default' do
    lambda {@resource.destination}.should raise_error(NotImplementedError)
  end

  it 'does not compute the extension by default' do
    lambda {@resource.extension}.should raise_error(NotImplementedError)
  end

  it 'does not compute the url by default' do
    lambda {@resource.url}.should raise_error(NotImplementedError)
  end

  it 'does not compute the dirty state by default' do
    lambda {@resource.dirty?}.should raise_error(NotImplementedError)
  end

  it 'does not implement the _read method by default' do
    lambda {@resource._read}.should raise_error(NotImplementedError)
  end

  it 'provides the path to the file' do
    @resource.path.should == @filename
  end

  it 'computes the directory of the file with the content folder removed' do
    @resource.dir.should == ''

    resource = Webby::Resources::Resource.
                   new(File.join(%w[content tumblog index.txt]))
    resource.dir.should == 'tumblog'
  end

  it 'returns the bare filename' do
    @resource.filename.should == 'index'

    resource = Webby::Resources::Resource.
                   new(File.join(%w[content tumblog rss.txt]))
    resource.filename.should == 'rss'
  end

  it 'returns the path-based extension' do
    @resource.ext.should == 'txt'
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

end  # describe Webby::Resources::Resource

# EOF
