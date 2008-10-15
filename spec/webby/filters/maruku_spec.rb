
require ::File.expand_path(
    ::File.join(::File.dirname(__FILE__), %w[.. .. spec_helper]))

# ---------------------------------------------------------------------------
describe 'Webby::Filters::Maruku' do

  it 'should regsiter the maruku filter handler' do
    Webby::Filters._handlers['maruku'].should_not be_nil
  end

  if try_require('maruku')

    it 'processes maruku markup into HTML' do
      input = "## Heading Two\n\nAnd some text about this heading."
      output = Webby::Filters._handlers['maruku'].call(input)

      output.should == %Q{<h2 id='heading_two'>Heading Two</h2>\n\n<p>And some text about this heading.</p>}
    end

  else

    it 'raises an error when maruku is used but not installed' do
      input = "## Heading Two\n\nAnd some text about this heading."
      lambda {Webby::Filters._handlers['maruku'].call(input)}.should raise_error(Webby::Error, "'maruku' must be installed to use the maruku filter")
    end

  end
end

# EOF
