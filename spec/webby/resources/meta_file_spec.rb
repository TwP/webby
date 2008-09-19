
require File.expand_path(
    File.join(File.dirname(__FILE__), %w[.. .. spec_helper]))

# -------------------------------------------------------------------------
describe Webby::Resources::MetaFile do

  it 'raises an error when created without an IO object' do
    lambda {Webby::Resources::MetaFile.new('string')}.should raise_error(
      ArgumentError, 'expecting an IO stream')
  end

  it 'returns the number of meta-data blocks at the top of a file' do
    fn = Webby.datapath %w[site content css coderay.css]
    File.open(fn, 'r') do |fd|
      mf = Webby::Resources::MetaFile.new(fd)
      mf.meta_count.should == 0
    end

    fn = Webby.datapath %w[site content index.txt]
    File.open(fn, 'r') do |fd|
      mf = Webby::Resources::MetaFile.new(fd)
      mf.meta_count.should == 1
    end

    fn = Webby.datapath %w[site content photos.txt]
    File.open(fn, 'r') do |fd|
      mf = Webby::Resources::MetaFile.new(fd)
      mf.meta_count.should == 3
    end
  end

  it 'determines the end of the final meta-data block' do
    fn = Webby.datapath %w[site content index.txt]
    File.open(fn, 'r') do |fd|
      mf = Webby::Resources::MetaFile.new(fd)
      mf.meta_end.should == 7
    end

    fn = Webby.datapath %w[site content photos.txt]
    File.open(fn, 'r') do |fd|
      mf = Webby::Resources::MetaFile.new(fd)
      mf.meta_end.should == 18
    end
  end

  # -----------------------------------------------------------------------
  describe '.each' do
    it 'yields each meta-data block' do
      fn = Webby.datapath %w[site content photos.txt]
      output = []
      File.open(fn, 'r') do |fd|
        mf = Webby::Resources::MetaFile.new(fd)
        mf.each {|h| output << h}
      end
      output.length.should == 3
      output.map {|h| h['title']}.should == [
        'First Photo',
        'Second Photo',
        'Third Photo'
      ]
      output.map {|h| h['directory']}.should == ['photos']*3
      output.map {|h| h['filename']}.should == %w[image1 image2 image3]

    end

    it 'yields a single meta-data block' do
      fn = Webby.datapath %w[site content index.txt]
      output = []
      File.open(fn, 'r') do |fd|
        mf = Webby::Resources::MetaFile.new(fd)
        mf.each {|h| output << h}
      end
      output.length.should == 1
      h = output.first
      h['title'].should == 'Home Page'
      h['filter'].should == %w[erb textile]
    end

    it 'raises an error if the meta-data is not a hash' do
      fn = Webby.datapath %w[hooligans bad_meta_data_1.txt]
      output = []
      File.open(fn, 'r') do |fd|
        mf = Webby::Resources::MetaFile.new(fd)
        lambda {
          mf.each {|h| output << h}
        }.should raise_error(Webby::Resources::MetaFile::Error)
      end
      output.length.should == 1
    end

    it "really doesn't like YAML syntax errors" do
      fn = Webby.datapath %w[hooligans bad_meta_data_2.txt]
      output = []
      File.open(fn, 'r') do |fd|
        mf = Webby::Resources::MetaFile.new(fd)
        lambda {
          mf.each {|h| output << h}
        }.should raise_error(Webby::Resources::MetaFile::Error)
      end
      output.length.should == 1
    end
  end

  # -----------------------------------------------------------------------
  describe '#meta_data' do
    it 'returns nil for regular files' do
      fn = Webby.datapath %w[site content css coderay.css]
      Webby::Resources::MetaFile.meta_data(fn).should be_nil
    end

    it 'returns a hash for pages' do
      fn = Webby.datapath %w[site content index.txt]
      h = Webby::Resources::MetaFile.meta_data(fn)

      h.should be_instance_of(Hash)
      h['created_at'].should be_instance_of(Time)
    end

    it 'returns a hash for layouts' do
      fn = Webby.datapath %w[site layouts default.txt]
      h = Webby::Resources::MetaFile.meta_data(fn)

      h.should be_instance_of(Hash)
      h.should == {
        'extension' => 'html',
        'filter'    => 'erb'
      }
    end
  end

  # -----------------------------------------------------------------------
  describe "#meta_data?" do
    it 'returns true for files with meta-data' do
      fn = Webby.datapath %w[site content index.txt]
      Webby::Resources::MetaFile.meta_data?(fn).should == true
    end

    it 'returns false for files without meta-data' do
      fn = Webby.datapath %w[site content css coderay.css]
      Webby::Resources::MetaFile.meta_data?(fn).should == false
    end
  end

  # -----------------------------------------------------------------------
  describe "#read" do
    it 'behaves the same as File#read for regular files' do
      fn = Webby.datapath %w[site content css coderay.css]
      Webby::Resources::MetaFile.read(fn).should == ::File.read(fn)
    end

    it 'returns only the content for pages' do
      fn = Webby.datapath %w[site content index.txt]
      lines = File.readlines(fn)
      lines = lines[7..-1].join

      Webby::Resources::MetaFile.read(fn).should == lines
    end

    it 'returns only the content for layouts' do
      fn = Webby.datapath %w[site layouts default.txt]
      lines = File.readlines(fn)
      lines = lines[4..-1].join

      Webby::Resources::MetaFile.read(fn).should == lines
    end
  end

end  # describe Webby::Resources::MetaFile

# EOF
