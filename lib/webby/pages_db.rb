# $Id$

module Webby

#
#
class PagesDB
  include Enumerable

  # call-seq:
  #    PagesDB.new
  #
  def initialize
    @db = Hash.new {|h,k| h[k] = []}
  end

  # call-seq:
  #    add( resource )
  #
  def add( page )
    @db[page.dir] << page
    self
  end
  alias :<< :add

  # call-seq:
  #    clear
  #
  def clear
    @db.clear
  end

  # call-seq:
  #    each {|resource| block}
  #
  def each( &b )
    keys = @db.keys.sort
    keys.each do |k|
      @db[k].sort.each(&b)
    end
  end

  # call-seq:
  #    find_by_name( name )
  #
  def find_by_name( name )
    self.find {|page| page.filename == name}
  end

  # call-seq:
  #    siblings( page, opts = {} )    => array
  #
  # Options include:
  #    :sorty_by => 'attribute'
  #    :reverse  => true
  #
  def siblings( page, opts = {} )
    ary = @db[page.dir].dup
    ary.delete page
    return ary unless opts.has_key? :sort_by

    m = opts[:sort_by]
    ary.sort! {|a,b| a.send(m) <=> b.send(m)}
    ary.reverse! if opts[:reverse]
    ary
  end

  # call-seq:
  #    children( page, opts = {} )    => array
  #
  # Options include:
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
    ary.sort! {|a,b| a.send(m) <=> b.send(m)}
    ary.reverse! if opts[:reverse]
    ary
  end

end  # class PagesDB
end  # module Webby

# EOF
