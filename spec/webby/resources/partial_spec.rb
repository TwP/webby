
require File.expand_path(
    File.join(File.dirname(__FILE__), %w[.. .. spec_helper]))

# -------------------------------------------------------------------------
describe Webby::Resources::Partial do
  before :each do
    @filename = File.join %w[content _partial.txt]
    @partial  = Webby::Resources::Partial.new(@filename)
  end

  it 'parses meta-data on initialization' do
    h = @partial._meta_data

    h.should_not be_empty
    h.should == {'filter' => 'erb'}
  end

  it 'uses the cairn file as the destination' do
    @partial.destination.should == ::Webby.cairn
  end

  it 'always returns nil as the url' do
    @partial.url.should be_nil
  end

  it 'reads the contents of the file' do
    str = @partial._read
    str.split($/).first.should == 'A partial has access to the page from which it was called. The title below will be the title of the page in which this partial is rendered.'
  end

  it 'uses the files extension as the extension' do
    @partial.extension.should equal(@partial.ext)
  end

  # -----------------------------------------------------------------------
  describe '.dirty?' do
    it 'overrides the dirty state based on the meta-data value' do
      @partial['dirty'] = true
      @partial.dirty?.should == true

      @partial['dirty'] = false
      @partial.dirty?.should == false
    end

    it 'returns true if the cairn file is missing' do
      @partial.dirty?.should == true
    end

    it 'returns false if the cairn file is present' do
      FileUtils.touch Webby.cairn
      @partial.dirty?.should == false
    end
  end

end  # describe Webby::Resources::Partial

# EOF
