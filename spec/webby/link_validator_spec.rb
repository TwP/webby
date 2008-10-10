require File.expand_path(
    File.join(File.dirname(__FILE__), %w[.. spec_helper]))

# ---------------------------------------------------------------------------
describe Webby::LinkValidator do
  before do
    @validator = Webby::LinkValidator.new
    @@old = Webby.site.output_dir
    Webby.site.output_dir = Webby.datapath('html')
  end

  after do
    Webby.site.output_dir = @@old
  end

  describe ".validate" do
    it "passes options to a new validator" do
      new_validator = stub('validator', :validate => true)
      Webby::LinkValidator.should_receive(:new).with(:options).and_return(new_validator)
      Webby::LinkValidator.validate(:options)
    end

    it "checks each file" do
      #TODO: test fake site
      files = ["a file", "another file"]
      Dir.stub!(:glob).and_return(files)

      validator = Webby::LinkValidator.new
      files.each do |file|
        validator.should_receive(:check_file).with(file)
      end
      validator.validate
    end
  end

  describe "checking a file" do
    describe "with an anchor" do
      before do
        @filename = Webby.datapath('html', 'anchor.html')
      end

      it "validates the anchor" do
        @validator.should_receive(:validate_anchor)
        @validator.check_file(@filename)
      end

      it "does not add the file to the valid uri list" do
        lambda { @validator.check_file(@filename) }.should_not change(@validator.instance_variable_get('@valid_uris'), :size)
      end

      it "***CURRENTLY*** returns nil" do
        @validator.check_file(@filename).should be_nil
      end
    end

    describe "with a valid relative href" do
      before do
        @filename = Webby.datapath('html', 'relative.html')
      end

      it "adds the file to the valid uri list" do
        lambda { @validator.check_file(@filename) }.should change(@validator.instance_variable_get('@valid_uris'), :size).by(1)
      end

      it "***CURRENTLY*** returns nil" do
        @validator.check_file(@filename).should be_nil
      end
    end

    describe "with an invalid relative href" do
      before do
        @filename = Webby.datapath('html', 'invalid-relative.html')
      end

      it "does not add the file to the invalid uri list" do
        lambda { @validator.check_file(@filename) }.should_not change(@validator.instance_variable_get('@valid_uris'), :size)
      end

      it "***CURRENTLY*** returns nil" do
        @validator.check_file(@filename).should be_nil
      end
    end

    describe "with a valid relative href that contains an anchor" do
      before do
        @filename = Webby.datapath('html', 'relative-anchor.html')
      end

      it "adds the file to the valid uri list" do
        lambda { @validator.check_file(@filename) }.should change(@validator.instance_variable_get('@valid_uris'), :size).by(1)
      end

      it "***CURRENTLY*** returns nil" do
        @validator.check_file(@filename).should be_nil
      end
    end

    describe "with a valid relative href that contains an invalid anchor" do
      before do
        @filename = Webby.datapath('html', 'relative-invalid-anchor.html')
      end

      it "does not the file to the valid uri list" do
        lambda { @validator.check_file(@filename) }.should_not change(@validator.instance_variable_get('@valid_uris'), :size)
      end

      it "***CURRENTLY*** returns nil" do
        @validator.check_file(@filename).should be_nil
      end
    end

    if $test_externals
      describe "with a valid external href" do
        before do
          FakeWeb.register_uri('http://www.google.com/', :string => 'google')
          @filename = Webby.datapath('html', 'external.html')
          @validator.validate_externals = true
        end

        it "adds the file to the valid uri list" do
          lambda { @validator.check_file(@filename) }.should change(@validator.instance_variable_get('@valid_uris'), :size).by(1)
        end

        it "does not add the file to the invalid uri list" do
          lambda { @validator.check_file(@filename) }.should_not change(@validator.instance_variable_get('@invalid_uris'), :size)
        end

        it "***CURRENTLY*** returns nil" do
          @validator.check_file(@filename).should be_nil
        end
      end

      describe "with an invalid external href" do
        before do
          FakeWeb.register_uri('http://www.google.com/', :string => 'google', :status => [ 404, "Not Found" ])
          @filename = Webby.datapath('html', 'external.html')
          @validator.validate_externals = true
        end

        it "does not add the file to the valid uri list" do
          lambda { @validator.check_file(@filename) }.should_not change(@validator.instance_variable_get('@valid_uris'), :size)
        end

        it "adds the file to the invalid uri list" do
          lambda { @validator.check_file(@filename) }.should change(@validator.instance_variable_get('@invalid_uris'), :size).by(1)
        end

        it "***CURRENTLY*** returns nil" do
          @validator.check_file(@filename).should be_nil
        end
      end
    end
  end
end
