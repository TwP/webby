
require ::File.expand_path(
    ::File.join(::File.dirname(__FILE__), %w[.. spec_helper]))

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

    it "should always capitlize the first and last words of the title" do
      'a little bit of'.titlecase.should == 'A Little Bit Of'
      'iTunes is being released'.titlecase.should == 'iTunes Is Being Released'
      %q("a quoted title if").titlecase.should == %q("A Quoted Title If")
      %q(and if you do via?).titlecase.should == %q(And if You Do Via?)
    end

    it "should caplitalize a small word after a colon" do
      %q(starting sub-phrase with a small word: a trick, perhaps?).titlecase.
          should == %q(Starting Sub-Phrase With a Small Word: A Trick, Perhaps?)

      %q(sub-phrase with a small word in quotes: 'a trick, perhaps?').titlecase.
          should == %q(Sub-Phrase With a Small Word in Quotes: 'A Trick, Perhaps?')

      %q(sub-phrase with a small word in quotes: "a trick, perhaps?").titlecase.
          should == %q(Sub-Phrase With a Small Word in Quotes: "A Trick, Perhaps?")
    end

    it "should properly handle contractions" do
      %q(this isn't going to work).titlecase.
          should == %q(This Isn't Going to Work)

      %q(MicroSoft won't go down that route).titlecase.
          should == %q(MicroSoft Won't Go Down That Route)
    end

    it "should capitalize phrases inside quotations" do
      %q(Q&A with steve jobs: 'that's what happens in technology').titlecase.
          should == %q(Q&A With Steve Jobs: 'That's What Happens in Technology')
    end

  end
end

# EOF
