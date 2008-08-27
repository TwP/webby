
require File.expand_path(
    File.join(File.dirname(__FILE__), %w[.. .. spec_helper]))

# -------------------------------------------------------------------------
describe Webby::Resources::MetaFile do

  it 'raises an error when created without an IO object' do
    lambda {Webby::Resources::MetaFile.new('string')}.should raise_error(
      ArgumentError, 'expecting an IO stream')
  end

  # -----------------------------------------------------------------------
  describe '#meta_data' do
    it 'returns nil for regular files' do
      fn = Webby.datapath %w[content css coderay.css]
      Webby::Resources::MetaFile.meta_data(fn).should be_nil
    end

    it 'returns a hash for pages' do
      fn = Webby.datapath %w[content index.txt]
      h = Webby::Resources::MetaFile.meta_data(fn)

      h.should be_instance_of(Hash)
      h['created_at'].should be_instance_of(Time)
    end

    it 'returns a hash for layouts' do
      fn = Webby.datapath %w[layouts default.txt]
      h = Webby::Resources::MetaFile.meta_data(fn)

      h.should be_instance_of(Hash)
      h.should == {
        'extension' => 'html',
        'filter'    => 'erb'
      }
    end
  end

  # -----------------------------------------------------------------------
  describe "#read" do
    it 'behaves the same as File#read for regular files' do
      fn = Webby.datapath %w[content css coderay.css]
      Webby::Resources::MetaFile.read(fn).should == ::File.read(fn)
    end

    it 'returns only the content for pages' do
      fn = Webby.datapath %w[content index.txt]
      lines = File.readlines(fn)
      lines = lines[7..-1].join

      Webby::Resources::MetaFile.read(fn).should == lines
    end

    it 'returns only the content for layouts' do
      fn = Webby.datapath %w[layouts default.txt]
      lines = File.readlines(fn)
      lines = lines[4..-1].join

      Webby::Resources::MetaFile.read(fn).should == lines
    end
  end

end  # describe Webby::Resources::MetaFile

# EOF
