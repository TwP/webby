
require ::File.expand_path(
    ::File.join(::File.dirname(__FILE__), 'spec_helper'))

describe String do

  it "should join other strings to form a file path" do
    path = 'foo' / 'bar' / 'baz'
    path.should == ::File.join(%w[foo bar baz])
  end

  describe "when applying title case" do
    it "should not capitalize small words" do
      'and on the other hand of fate we have a ring'.titlecase.
          should == 'And on the Other Hand of Fate We Have a Ring'
    end

    it "should not modify words that contain capital letters other than the first character" do
      'the iTunes store is down'.titlecase.
          should == 'The iTunes Store Is Down'
      "what's up with the MacUpdate site".titlecase.
          should == "What's Up With the MacUpdate Site"
    end

    it "should skip words with line dots (example.com or del.icio.us)" do
      'the website example.com is used in documentation'.titlecase.
          should == 'The Website example.com Is Used in Documentation'
    end

    it "should always capitlize the first and last words of the title"

    it "should caplitalize a small word after a colon" do
      %q(starting sub-phrase with a small word: a trick, perhaps?).titlecase.
          should == %q(Starting Sub-Phrase With a Small Word: A Trick, Perhaps?)

      %q(sub-phrase with a small word in quotes: 'a trick, perhaps?').titlecase.
          should == %q(Sub-Phrase With a Small Word in Quotes: 'A Trick, Perhaps?')

      %q(sub-phrase with a small word in quotes: "a trick, perhaps?").titlecase.
          should == %q(Sub-Phrase With a Small Word in Quotes: "A Trick, Perhaps?")
    end

    it "should properly handle possesives and contractions"
    it "should capitalize phrases inside quotations"
  end
end

# EOF
