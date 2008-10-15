
require ::File.expand_path(
    ::File.join(::File.dirname(__FILE__), %w[.. .. spec_helper]))

# ---------------------------------------------------------------------------
describe 'Webby::Filters::Textile' do

  it 'should regsiter the textile filter handler' do
    Webby::Filters._handlers['textile'].should_not be_nil
  end

  if try_require('redcloth')

    it 'processes textile markup into HTML' do
      input = "p(foo). this is a paragraph of text"
      output = Webby::Filters._handlers['textile'].call(input)

      output.should == %q{<p class="foo">this is a paragraph of text</p>}
    end

  else

    it 'raises an error when RedCloth is used but not installed' do
      input = "p(foo). this is a paragraph of text"
      lambda {Webby::Filters._handlers['textile'].call(input)}.should raise_error(Webby::Error, "'RedCloth' must be installed to use the textile filter")
    end

  end
end

# EOF
