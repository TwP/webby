
require File.expand_path(
    File.join(File.dirname(__FILE__), %w[.. .. spec_helper]))

# -------------------------------------------------------------------------
describe Webby::Resources::DB do

  before :each do
    layout = Webby::Resources::Layout.
             new(Webby.datapath %w[layouts tumblog default.txt])
    Webby::Resources.stub!(:find_layout).and_return(layout)

    @db = Webby::Resources::DB.new
    Dir.glob('content/tumblog/**/*').each do |fn|
      next unless test(?f, fn)
      @db.add Webby::Resources::Page.new(fn)
    end
    @db_hash = @db.instance_variable_get(:@db)
  end

  it 'stores resources by directory' do
    @db_hash.keys.sort.should == %w[
      tumblog
      tumblog/200806/the-noble-chicken
      tumblog/200807/historical-perspectives-on-the-classic-chicken-joke
      tumblog/200807/mad-city-chickens
      tumblog/200807/the-wisdom-of-the-dutch
      tumblog/200807/up-a-tree
    ]
    @db_hash['tumblog'].length.should == 2
    @db_hash['tumblog/200807/up-a-tree'].length.should == 1
    @db_hash['tumblog/200807/up-a-tree'].first.filename.should == 'index'
  end

  it 'replaces resources when adding' do
    ary = @db_hash['tumblog/200806/the-noble-chicken']
    page = ary.first

    @db.add Webby::Resources::Page.
            new('content/tumblog/200806/the-noble-chicken/index.txt')

    ary.first.should_not equal(page)
    ary.first.path.should == page.path
  end

  it 'clears the stored resources' do
    @db_hash.should_not be_empty
    @db.clear
    @db_hash.should be_empty
  end

  it 'iterates over the resources in order' do
    ary = []
    @db.each {|page| ary << page.url}
    ary.should == %w[
      /tumblog
      /tumblog/rss.xml
      /tumblog/200806/the-noble-chicken
      /tumblog/200807/historical-perspectives-on-the-classic-chicken-joke
      /tumblog/200807/mad-city-chickens
      /tumblog/200807/the-wisdom-of-the-dutch
      /tumblog/200807/up-a-tree
    ]
  end

  it 'returns the parent of a resource' do
    page = Webby::Resources::Page.new('content/tumblog/index.txt')
    parent = @db.parent_of(page)
    (parent == nil).should == true

    page = Webby::Resources::Page.new('content/tumblog/rss.txt')
    parent = @db.parent_of(page)
    parent.url.should == '/tumblog'

    page = Webby::Resources::Page.new('content/tumblog/200807/up-a-tree/index.txt')
    parent = @db.parent_of(page)
    parent.url.should == '/tumblog'
  end

  it 'returns the siblings of a resource' do
    page = Webby::Resources::Page.new('content/tumblog/index.txt')
    siblings = @db.siblings(page)

    siblings.length.should == 1
    siblings.first.path.should == 'content/tumblog/rss.txt'

    page = Webby::Resources::Page.new('content/tumblog/200806/the-noble-chicken/index.txt')
    siblings = @db.siblings(page)
    siblings.should be_empty
  end

  # -----------------------------------------------------------------------
  describe '.children' do
    it 'returns the children of a resource' do
      page = Webby::Resources::Page.new('content/tumblog/index.txt')
      children = @db.children(page)

      children.length.should == 5
      children.map {|page| page.url}.sort.should == %w[
        /tumblog/200806/the-noble-chicken
        /tumblog/200807/historical-perspectives-on-the-classic-chicken-joke
        /tumblog/200807/mad-city-chickens
        /tumblog/200807/the-wisdom-of-the-dutch
        /tumblog/200807/up-a-tree
      ]
    end

    it 'returns them in the specified sort order' do
      page = Webby::Resources::Page.new('content/tumblog/index.txt')
      children = @db.children(page, :sort_by => :url)

      children.length.should == 5
      children.map {|page| page.url}.should == %w[
        /tumblog/200806/the-noble-chicken
        /tumblog/200807/historical-perspectives-on-the-classic-chicken-joke
        /tumblog/200807/mad-city-chickens
        /tumblog/200807/the-wisdom-of-the-dutch
        /tumblog/200807/up-a-tree
      ]
    end

    it 'returns them in the reversed sort order' do
      page = Webby::Resources::Page.new('content/tumblog/index.txt')
      children = @db.children(page, :sort_by => :url, :reverse => true)

      children.length.should == 5
      children.map {|page| page.url}.should == %w[
        /tumblog/200806/the-noble-chicken
        /tumblog/200807/historical-perspectives-on-the-classic-chicken-joke
        /tumblog/200807/mad-city-chickens
        /tumblog/200807/the-wisdom-of-the-dutch
        /tumblog/200807/up-a-tree
      ].reverse
    end
  end

  # -----------------------------------------------------------------------
  describe '.find' do
    it 'needs some specs'
  end

end  # describe Webby::Resources::DB

# EOF
