
require File.expand_path(
    File.join(File.dirname(__FILE__), %w[.. spec_helper]))

# ---------------------------------------------------------------------------
describe Webby::Renderer do
  before :each do
    layout = Webby::Resources::Layout.
             new(Webby.datapath %w[layouts tumblog default.txt])
    Webby::Resources.stub!(:find_layout).and_return(layout)

    @filename = File.join %w[content tumblog index.txt]
    @page = Webby::Resources::Page.new(@filename)
    @renderer = Webby::Renderer.new(@page)
  end

  it 'paginates a set of items' do
    items = %w[one two three four five six seven eight]
    output = []

    @renderer.instance_variable_get(:@pager).should be_nil

    # the first page of items
    @renderer.paginate(items, 3) {|item| output << item}
    pager = @renderer.instance_variable_get(:@pager)

    pager.should_not be_nil
    pager.number_of_pages.should == 3
    pager.prev?.should == false
    pager.next?.should == true

    output.should == %w[one two three]
    @page.destination.should == 'output/tumblog/index.html'

    # go to the next page of items
    @renderer._next_page.should == true
    output.should == %w[one two three]

    pager = @renderer.instance_variable_get(:@pager)
    pager.should_not be_nil
    pager.number_of_pages.should == 3
    pager.prev?.should == true
    pager.next?.should == true

    @page.destination.should == 'output/tumblog/index2.html'

    @renderer.paginate(items, 3) {|item| output << item}
    output.should == %w[one two three four five six]

    # go to the last page of items
    @renderer._next_page.should == true
    output.should == %w[one two three four five six]

    pager = @renderer.instance_variable_get(:@pager)
    pager.should_not be_nil
    pager.number_of_pages.should == 3
    pager.prev?.should == true
    pager.next?.should == false

    @page.destination.should == 'output/tumblog/index3.html'

    @renderer.paginate(items, 3) {|item| output << item}
    output.should == %w[one two three four five six seven eight]

    # after the last page
    @renderer._next_page.should == false
    pager = @renderer.instance_variable_get(:@pager)
    pager.should be_nil
    @page.destination.should == 'output/tumblog/index.html'
  end

  it 'needs some more specs'
end

# EOF
