
require ::File.expand_path(
    ::File.join(::File.dirname(__FILE__), %w[.. .. spec_helper]))

# ---------------------------------------------------------------------------
describe Webby::Filters::Outline do

  before :all do
    @input = Webby::Resources::MetaFile.read(
                 Webby.datapath(%w[outline basic.txt]))
  end

  it 'should regsiter the outline filter handler' do
    Webby::Filters._handlers['outline'].should_not be_nil
  end

  it 'generates outline formatting for HTML heading tags' do
    output = File.read(Webby.datapath(%w[outline basic.out]))

    outline = Webby::Filters::Outline.new(@input)
    outline.filter.should == output
  end

  it 'starts numbering at an arbitrary value' do
    input = @input.sub(%r/<toc \/>/, '<toc numbering_start="3" />')
    output = File.read(Webby.datapath(%w[outline numbering.out]))

    outline = Webby::Filters::Outline.new(input)
    outline.filter.should == output
  end

  it 'limits the range of headers the table of contents covers' do
    input = @input.sub(%r/<toc \/>/, '<toc toc_range="h1-h3" />')
    output = File.read(Webby.datapath(%w[outline toc_range_1.out]))

    outline = Webby::Filters::Outline.new(input)
    outline.filter.should == output

    input = @input.sub(%r/<toc \/>/, '<toc toc_range="h2-h4" />')
    output = File.read(Webby.datapath(%w[outline toc_range_2.out]))

    outline = Webby::Filters::Outline.new(input)
    outline.filter.should == output
  end

  it 'uses different list styling for the table of contents' do
    input = @input.sub(%r/<toc \/>/, '<toc toc_style="ul" />')
    output = File.read(Webby.datapath(%w[outline toc_style.out]))

    outline = Webby::Filters::Outline.new(input)
    outline.filter.should == output
  end

  it 'performs outline numbering without creatng a table of contents' do
    input = @input.sub(%r/<toc \/>/, '')
    output = File.read(Webby.datapath(%w[outline numbering_only.out]))

    outline = Webby::Filters::Outline.new(input)
    outline.filter.should == output
  end

  it 'detects mis-ordered heading tags' do
    input = <<-HTML
      <h2>Heading Three</h2>
      <h3>Heading Two</h3>
      <h1>Heading One</h1>
    HTML
    outline = Webby::Filters::Outline.new(input)

    lambda {outline.filter}.should raise_error(
      Webby::Error, "heading tags are not in order, cannot outline"
    )
  end

  it 'does not clobber other HTML tags' do
    html = <<-HTML
    <div>
      <p>This is the title</p>
      <toc />
      <p>And some sampler text</p>
    </div>
    HTML
    input = @input.sub(%r/<toc \/>/, html)
    output = File.read(Webby.datapath(%w[outline no_clobber.out]))

    outline = Webby::Filters::Outline.new(input)
    outline.filter.should == output
  end

end

# EOF
