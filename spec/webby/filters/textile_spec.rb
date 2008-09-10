
require ::File.expand_path(
    ::File.join(::File.dirname(__FILE__), %w[.. .. spec_helper]))

# ---------------------------------------------------------------------------
describe 'Webby::Filters::Textile' do

  it 'should regsiter the textile filter handler' do
    Webby::Filters._handlers['textile'].should_not be_nil
  end

  it 'processes textile markup into HTML' do
    input = "p(foo). this is a paragraph of text"
    output = Webby::Filters._handlers['textile'].call(input)

    output.should == %q{<p class="foo">this is a paragraph of text</p>}
  end
end

# EOF
