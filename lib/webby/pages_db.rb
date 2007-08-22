# $Id$

module Webby

#
#
class PagesDB
  include Enumerable

  def initialize
    @db = Hash.new {|h,k| h[k] = []}
  end

  def add( page )
    @db[page.dir] << page
    self
  end
  alias :<< :add

  def clear
    @db.clear
  end

  def each( &b )
    keys = @db.keys.sort
    keys.each do |k|
      @db[k].sort.each(&b)
    end
  end

  def find_by_name( name )
    self.find {|page| page.filename == name}
  end

  def siblings( page, opts = {} )
    ary = @db[page.dir].dup
    ary.delete page
    return ary unless opts.has_key? :sort_by

    m = opts[:sort_by]
    ary.sort! {|a,b| a.send(m) <=> b.send(m)}
    ary.reverse! if opts[:reverse]
    ary
  end

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
