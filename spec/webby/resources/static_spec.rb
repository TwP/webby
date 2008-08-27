
require File.expand_path(
    File.join(File.dirname(__FILE__), %w[.. .. spec_helper]))

# -------------------------------------------------------------------------
describe Webby::Resources::Static do
  before :all do
    @filename = File.join %w[content css coderay.css]
    @static   = Webby::Resources::Static.new(@filename)
  end

  it 'contains no meta-data' do
    @static._meta_data.should be_empty
  end

  it 'uses the path remounted to the output directory as the destination' do
    @static.destination.should == 'output/css/coderay.css'
  end

  it 'returns destination without the output directory as the url' do
    @static.url.should == '/css/coderay.css'
  end

  it 'reads the contents of the file' do
    str = @static._read
    str.split($/).first.should == '.CodeRay {'
  end

  it 'uses the file extension as the extension' do
    @static.extension.should equal(@static.ext)
  end

  # -----------------------------------------------------------------------
  describe '.dirty?' do
    it 'returns true if the output file is missing' do
      @static.dirty?.should == true
    end

    it 'returns false if the output file is present' do
      dest = @static.destination
      FileUtils.mkdir_p File.dirname(dest)
      FileUtils.touch dest
      @static.dirty?.should == false
    end
  end

end  # describe Webby::Resources::Static

# EOF
