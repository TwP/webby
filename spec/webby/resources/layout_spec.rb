
require File.expand_path(
    File.join(File.dirname(__FILE__), %w[.. .. spec_helper]))

# -------------------------------------------------------------------------
describe Webby::Resources::Layout do
  before :each do
    layout = Webby::Resources::Layout.
             new(Webby.datapath(%w[site layouts tumblog default.txt]))
    Webby::Resources.stub!(:find_layout).and_return(layout)

    @default = File.join %w[layouts tumblog default.txt]
    @post    = File.join %w[layouts tumblog post.txt]
    @layout  = Webby::Resources::Layout.new(@default)
  end

  it 'parses meta-data on initialization' do
    h = @layout._meta_data

    h.should_not be_empty
    h.should == {
      'extension' => 'html',
      'filter'    => 'erb'
    }
  end

  it 'uses the cairn file as the destination' do
    @layout.destination.should == ::Webby.cairn
  end

  it 'always returns nil as the url' do
    @layout.url.should be_nil
  end

  it 'reads the contents of the file' do
    layout = Webby::Resources::Layout.new(@post)
    str = layout._read
    str.split($/).first.should == '<div class="post">'
  end

  # -----------------------------------------------------------------------
  describe '.extension' do
    it 'uses the extension from the meta-data if present' do
      @layout.extension.should == 'html'
    end

    it "returns nil if no extension is found in the meta-data" do
      @layout._meta_data.delete('extension')
      @layout.extension.should be_nil
    end

    it "uses the parent layout's extension if a parent layout is present" do
      layout = Webby::Resources::Layout.new(@post)
      layout.extension.should == 'html'

      layout._meta_data.delete('layout')
      layout.extension.should be_nil
    end
  end

  # -----------------------------------------------------------------------
  describe '.dirty?' do
    it 'overrides the dirty state based on the meta-data value' do
      @layout['dirty'] = true
      @layout.dirty?.should == true

      @layout['dirty'] = false
      @layout.dirty?.should == false
    end

    it 'returns true if the output file is missing' do
      @layout.dirty?.should == true
    end

    it 'returns false if the cairn file is present' do
      FileUtils.touch Webby.cairn
      @layout.dirty?.should == false
    end
  end

end  # describe Webby::Resources::Layout

# EOF
