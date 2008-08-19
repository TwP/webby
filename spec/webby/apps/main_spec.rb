
require ::File.expand_path(
    ::File.join(::File.dirname(__FILE__), %w[.. .. spec_helper]))

# ---------------------------------------------------------------------------
describe Webby::Apps::Main do
  before do
    @main = Webby::Apps::Main.new
  end

  describe "#capture_command_line_args" do
    it "should set the raw arguments" do
      raw = ["The Raw Arguments"]
      args = @main.send :capture_command_line_args, raw
      args.raw.should == raw
    end

    it "should set the page with one argument by downcasing" do
      page = "This-is-a-page"
      args = @main.send :capture_command_line_args, [page]
      args.page.should == page.downcase
    end

    it "should set the page with two or more arguments by joining" do
      page = %w(this is a page)
      args = @main.send :capture_command_line_args, page
      args.page.should == page.join('-')
    end

    # NOTE: should this be "foo/bar"?
    it "should set the dir from the page's dirname" do
      page = "foo/bar/this-is-a-page.txt"
      args = @main.send :capture_command_line_args, [page]
      args.dir.should == "foo/bar"
    end

    it "should set the slug from the page's basename" do
      page = "foo/bar/this-is-a-page.txt"
      args = @main.send :capture_command_line_args, [page]
      args.slug.should == "this-is-a-page"
    end

    it "should turn the slug into a url" do
      page = "10% Inspiration & 90% Perspiration"
      args = @main.send :capture_command_line_args, [page]
      args.slug.should == "10-percent-inspiration-and-90-percent-perspiration"
    end

    it "should set the page by combining the dir and slug" do
      page = "10% Inspiration & 90% Perspiration"
      args = @main.send :capture_command_line_args, [page]
      args.page.should == "10-percent-inspiration-and-90-percent-perspiration"

      page = "foo/bar/10% Inspiration & 90% Perspiration"
      args = @main.send :capture_command_line_args, [page]
      args.page.should == "foo/bar/10-percent-inspiration-and-90-percent-perspiration"
    end

    # TODO: Is this desired behavior?
    it "should set the title by joining the raw args, getting the basename, and titlecasing"  do
      page = "foo/bar/this-is-a-page.txt"
      args = @main.send :capture_command_line_args, [page]
      args.title.should == "This-Is-a-Page"
    end
  end
end
