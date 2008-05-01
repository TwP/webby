
require ::File.join(::File.dirname(__FILE__), %w[.. .. spec_helper])

# ---------------------------------------------------------------------------
describe Webby::Resources::File do

  FN = ::File.expand_path(::File.join(::File.dirname(__FILE__), '..', '..', 'lorem_ipsum.txt'))
  FN_YAML = FN.gsub %r/\.txt\z/, '_yaml.txt'
  LINES = [
    "Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Nulla orci\n",
    "ante, aliquet ac, vulputate ut, suscipit et, sapien. Integer elementum\n",
    "nisi quis magna tincidunt mattis. Aliquam semper. Pellentesque pretium.\n",
    "Ut a ligula sit amet pede malesuada laoreet. Ut et purus. Morbi turpis\n",
    "justo, pharetra vitae, consequat a, sodales vitae, tortor. Donec non\n",
    "massa. Maecenas adipiscing venenatis nisi. Proin vulputate lorem posuere\n",
    "mi. Cras sagittis. Pellentesque tortor mauris, accumsan vitae, ultrices\n",
    "vel, tristique ultricies, eros. Donec fringilla hendrerit mauris. Nam in\n",
    "orci. Curabitur congue consectetuer leo. Donec ut pede. Proin et lorem.\n",
    "Aliquam eget lacus. In nibh.\n"
  ]

  before do
    ::File.open(FN,'w') {|fd| fd.write LINES}
    ::File.open(FN_YAML,'w') do |fd|
      fd.write "--- \n- one\n- two\n- three\n--- \n"
      fd.write LINES
    end
  end

  after do 
    ::FileUtils.rm_f(FN)
    ::FileUtils.rm_f(FN_YAML)
  end

  it 'should return nil for meta-data on regular files' do
    begin
      fd = Webby::Resources::File.new FN, 'r'
      fd.meta_data.should be_nil

      fd.readlines.should == LINES
    ensure
      fd.close
    end
  end

  it 'should add meta-data to the top of a file' do
    Webby::Resources::File.open(FN,'a+') do |fd|
      fd.meta_data.should be_nil
      fd.meta_data = %w(one two three)
    end

    Webby::Resources::File.open(FN,'r') do |fd|
      fd.meta_data.should == %w(one two three)
    end

    ::File.open(FN_YAML, 'r') do |fd|
      ary = LINES.dup
      ary.insert 0, [
        "--- \n",
        "- one\n",
        "- two\n",
        "- three\n",
        "--- \n"
      ]
      fd.readlines.should == ary.flatten
    end
  end

  it 'should remove the meta-data when set to nil' do
    Webby::Resources::File.open(FN_YAML,'a+') do |fd|
      fd.meta_data.should == %w(one two three)
      fd.meta_data = nil
    end

    Webby::Resources::File.open(FN_YAML,'r') do |fd|
      fd.meta_data.should be_nil
    end

    ::File.open(FN_YAML, 'r') do |fd|
      fd.readlines.should == LINES
    end
  end

  it 'should skip the meta-data when reading from the file' do
    begin
      fd = Webby::Resources::File.new FN_YAML, 'r'
      fd.meta_data.should == %w(one two three)

      fd.getc.should == ?L;                        fd.seek 0
      fd.gets.should == LINES.first;               fd.seek 0
      fd.read(5).should == 'Lorem';                fd.seek 0
      fd.read_nonblock(11) == 'Lorem ipsum';       fd.seek 0
      fd.readchar.should == ?L;                    fd.seek 0
      fd.readline.should == LINES.first;           fd.seek 0
      fd.readlines.should == LINES;                fd.seek 0
      fd.readpartial(11).should == 'Lorem ipsum';  fd.seek 0

    ensure
      fd.close
    end
  end
end  # describe Webby::Resources::File

# EOF
