
require ::File.expand_path(
    ::File.join(::File.dirname(__FILE__), %w[.. .. spec_helper]))

# ---------------------------------------------------------------------------
describe Webby::Filters::BasePath do

  before :all do
    @input = <<-HTML
<html>
<head>
%s
</head>
<body>
%s
</body>
</html>
    HTML
  end

  before :each do
    Webby.site.base = nil
    @xpaths = Webby.site.xpaths.dup
  end

  after :each do
    Webby.site.xpaths = @xpaths
  end

  it 'raises an exception if a new base has not been specified' do
    input = @input % ['', '<img src="/foo/picture.jpg" />']
    bp = Webby::Filters::BasePath.new(input, 'html')

    lambda {bp.filter}.
        should raise_error(TypeError, "can't convert nil into String")
  end

  it 'changes nothing with an empty base path' do
    Webby.site.base = ''
    input = @input % ['', '<img src="/foo/picture.jpg" />']

    bp = Webby::Filters::BasePath.new(input, 'html')
    bp.filter.should == <<-HTML
<html>
<head>

</head>
<body>
<img src="/foo/picture.jpg" />
</body>
</html>
    HTML
  end

  it 'substitutes the base path for xpath values that have a leading slash' do
    Webby.site.base = 'http://example.com'
    input = @input % ['', '<img src="/foo/picture.jpg" />']

    bp = Webby::Filters::BasePath.new(input, 'html')
    bp.filter.should == <<-HTML
<html>
<head>

</head>
<body>
<img src="http://example.com/foo/picture.jpg" />
</body>
</html>
    HTML
  end

  it 'operates on all entities in the input string' do
    Webby.site.base = 'http://webby.rubyforge.org'
    input = @input % ['', %Q(<img src="/foo/picture.jpg" />\n<a href="/page.html">Page Title</a>)]

    bp = Webby::Filters::BasePath.new(input, 'html')
    bp.filter.should == <<-HTML
<html>
<head>

</head>
<body>
<img src="http://webby.rubyforge.org/foo/picture.jpg" />
<a href="http://webby.rubyforge.org/page.html">Page Title</a>
</body>
</html>
    HTML
  end

  it 'only operates on entities defined in the xpaths configuration' do
    Webby.site.xpaths.delete '/html/body//a[@href]'
    Webby.site.base = 'http://webby.rubyforge.org'
    input = @input % ['', %Q(<img src="/foo/picture.jpg" />\n<a href="/page.html">Page Title</a>)]

    bp = Webby::Filters::BasePath.new(input, 'html')
    bp.filter.should == <<-HTML
<html>
<head>

</head>
<body>
<img src="http://webby.rubyforge.org/foo/picture.jpg" />
<a href="/page.html">Page Title</a>
</body>
</html>
    HTML
  end

  it 'is restrictive to the configured xpaths' do
    Webby.site.base = 'not a real site'
    input = @input % ['<foo src="/foo/picture.jpg" />', '<a href="/page.html">Page Title</a>']

    bp = Webby::Filters::BasePath.new(input, 'html')
    bp.filter.should == <<-HTML
<html>
<head>
<foo src="/foo/picture.jpg" />
</head>
<body>
<a href="not a real site/page.html">Page Title</a>
</body>
</html>
    HTML
  end

  it 'registers a "basepath" filter in the filters module' do
    handler = Webby::Filters._handlers['basepath']
    handler.should_not be_nil
    handler.arity.should == 2
  end

  it 'leaves the input text unchanged if a base path is not configured' do
    cursor = mock("Cursor")
    page = mock("Page")
    cursor.stub!(:page).and_return(page)
    page.stub!(:extension).and_return('html')
    input = @input % ['', '<img src="/foo/picture.jpg" />']

    handler = Webby::Filters._handlers['basepath']
    output = handler.call(input, cursor)

    output.should equal(input)
  end

  it 'modifies text when a base path is configured' do
    cursor = mock("Cursor")
    page = mock("Page")
    cursor.stub!(:page).and_return(page)
    page.stub!(:extension).and_return('html')
    Webby.site.base = 'http://example.com'
    input = @input % ['', '<img src="/foo/picture.jpg" />']

    handler = Webby::Filters._handlers['basepath']
    handler.call(input, cursor).should == <<-HTML
<html>
<head>

</head>
<body>
<img src="http://example.com/foo/picture.jpg" />
</body>
</html>
    HTML
  end
end

# EOF
