# $Id$

module Webby

# A rudimentary "database" for holding resource objects and finding them.
# The database is held in a Ruby hash keyed by the directories in the
# content folder.
#
class PagesDB

  # call-seq:
  #    PagesDB.new
  #
  # Create a new pages database object. This is used to store resources and
  # to find them by their attributes.
  #
  def initialize
    @db = Hash.new {|h,k| h[k] = []}
  end

  # call-seq:
  #    add( resource )    => resource
  #
  # Add the given _resource_ to the database. It will not be added a second
  # time if it already exists in the database.
  #
  def add( page )
    ary = @db[page.dir]

    # make sure we don't duplicate pages
    ary.delete page if ary.include? page
    ary << page

    page
  end
  alias :<< :add

  # call-seq:
  #    clear    => self
  #
  # Removes all resources from the database.
  #
  def clear
    @db.clear
    self
  end

  # call-seq:
  #    each {|resource| block}
  #
  # Iterate over each resource in the database and pass it to the given
  # block.
  #
  def each( &b )
    keys = @db.keys.sort
    keys.each do |k|
      @db[k].sort.each(&b)
    end
    self
  end

  # call-seq:
  #    find( opts = {} )                       => resource or nil
  #    find( opts = {} ) {|resource| block}    => resource or nil
  #
  # Find a specific resource in the database. A resource can be found using
  # any combination of attributes by passing them in as options to the
  # +find+ method. This will used simple equality comparison to find the
  # resource.
  # 
  # For more complex finders, a block should be supplied. The usage
  # follows that of of the Enumerable#find method. The method will return
  # the first resource for which the block returns true.
  #
  # If the :all option is given as true, then all resources that match the
  # finder criteria will be returned in an array. If none are found, an
  # empty array will be returned.
  #
  # Options include:
  #
  #    :all
  #    :in_directory => 'directory'
  #
  # Examples:
  #
  #    # find the "index" resource in the "foo/bar" directory
  #    pages_db.find( :filename => 'index', :in_directory => 'foo/bar' )
  #
  #    # find all resources named "widgets" whose color is "blue"
  #    pages_db.find( :all, :name => 'widgets', :color => 'blue' )
  #
  #    # find all resources created in the past week
  #    pages_db.find( :all ) do |resource|
  #      resource.created_at > Time.now - (7 * 24 * 3600)
  #    end
  #
  def find( *args, &block )
    opts = Hash === args.last ? args.pop : {}
    find_all = args.include? :all

    dir = opts.has_key?(:in_directory) ? opts.delete(:in_directory) : nil
    if dir && !@db.has_key?(dir)
      raise RuntimeError, "unknown directory '#{dir}'"
    end

    block ||= lambda do |page|
      found = true
      opts.each do |key, value|
        found &&= page.__send__(key.to_sym) == value
        break if not found
      end
      found
    end

    ary = []
    search = dir ? @db[dir] : self
    search.each do |page|
      if block.call(page)
        ary << page
        break unless find_all
      end
    end

    return ary if find_all
    return ary.first 
  end

  # call-seq:
  #    siblings( page, opts = {} )    => array
  #
  # Returns an array of resources that are siblings of the given _page_
  # resource. A sibling is any resource that is in the same directory as the
  # _page_.
  #
  # Options include:
  #
  #    :sorty_by => 'attribute'
  #    :reverse  => true
  #
  def siblings( page, opts = {} )
    ary = @db[page.dir].dup
    ary.delete page
    return ary unless opts.has_key? :sort_by

    m = opts[:sort_by]
    ary.sort! {|a,b| a.__send__(m) <=> b.__send__(m)}
    ary.reverse! if opts[:reverse]
    ary
  end

  # call-seq:
  #    children( page, opts = {} )    => array
  #
  # Returns an array of resources that are children of the given _page_
  # resource. A child is any resource that exists in a subdirectory of the
  # page's directory.
  #
  # Options include:
  #
  #    :sorty_by => 'attribute'
  #    :reverse  => true
  #
  def children( page, opts = {} )
    rgxp = Regexp.new "\\A#{page.dir}/[^/]+"

    keys = @db.keys.find_all {|k| rgxp =~ k}
    ary  = keys.map {|k| @db[k]}
    ary.flatten!

    return ary unless opts.has_key? :sort_by

    m = opts[:sort_by]
    ary.sort! {|a,b| a.__send__(m) <=> b.__send__(m)}
    ary.reverse! if opts[:reverse]
    ary
  end

end  # class PagesDB
end  # module Webby

# EOF
