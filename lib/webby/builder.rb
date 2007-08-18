# $Id$

require 'find'
require 'fileutils'
require 'erb'

module Webby

#
#
class Builder

  class << self

    # call-seq:
    #    Builder.run( :rebuild => false )
    #
    def run( opts = {} )
      self.new.run opts
    end

    # call-seq:
    #    Builder.create( page, :from => template )
    #
    def create( page, opts = {} )
      tmpl = opts[:from]
      raise "template not given" unless tmpl
      raise "#{page} already exists" if test ?e, page

      puts "creating #{page}"
      FileUtils.mkdir_p File.dirname(page)
      str = ERB.new(::File.read(tmpl), nil, '-').result
      ::File.open(page, 'w') {|fd| fd.write str}

      return nil
    end
  end  # class << self

  # call-seq:
  #    run( :rebuild => false )
  #
  def run( opts = {} )
    unless test(?d, output_dir)
      puts "creating #{output_dir}"
      FileUtils.mkdir output_dir
    end

    load_layouts
    load_content

    Resource.pages.each do |page|
      next unless page.dirty? or opts[:rebuild]

      puts "creating #{page.destination}"

      # make sure the directory exists
      FileUtils.mkdir_p ::File.dirname(page.destination)

      # copy the resource to the output directory if it is static
      if page.is_static?
        FileUtils.cp page.path, page.destination

      # otherwise, layout the resource and write the results to
      # the output directory
      else
        ::File.open(page.destination, 'w') do |fd|
          fd.write Renderer.new(page).layout_page
        end
      end
    end

    # touch the output directory so we know when the
    # website was last generated
    FileUtils.touch output_dir

    return nil
  end


  private

  # call-seq:
  #    load_layouts
  #
  def load_layouts
    excl = Regexp.new exclude.join('|')

    ::Find.find(layout_dir) do |path|
      next unless test ?f, path
      next if path =~ excl
      Resource.new path
    end

    layouts = Resource.layouts

    # look for loops in the layout references -- i.e. a layout
    # eventually refers back to itself
    layouts.each do |lyt|
      stack = []
      while lyt
        if stack.include? lyt.filename
          stack << lyt.filename
          raise Error,
                "loop detected in layout references: #{stack.join(' > ')}"
        end
        stack << lyt.filename
        lyt = layouts.find_by_name lyt.layout
      end  # while
    end  # each
  end

  # call-seq:
  #    load_content
  #
  def load_content
    excl = Regexp.new exclude.join('|')
    Find.find(content_dir) do |path|
      next unless test ?f, path
      next if path =~ excl
      Resource.new path, ::Webby.page_defaults
    end
  end

  %w(output_dir layout_dir content_dir exclude).each do |key|
    self.class_eval <<-CODE
      def #{key}( ) ::Webby.config['#{key}'] end
    CODE
  end

end  # class Builder
end  # module Webby

# EOF
