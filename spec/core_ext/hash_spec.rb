
require ::File.expand_path(
    ::File.join(::File.dirname(__FILE__), %w[.. spec_helper]))

describe Hash do

  it "should stringify keys" do
    h = {
      :one  => 1,
      :two  => 2,
      3     => 'three',
      [3,4] => :thirty_four
    }.stringify_keys
    h.keys.sort.should == %w[3 34 one two]
  end

  it "should symbolize keys" do
    h = {
      'foo' => 42,
      'bar' => 'baz'
    }.symbolize_keys

    h.has_key?('foo').should == false
    h.has_key?('bar').should == false

    h.has_key?(:foo).should == true
    h.has_key?(:bar).should == true
  end

  describe "when sanitizing values" do
    [
     ['none', nil], ['nil', nil],
     ['true', true], ['yes', true],
     ['false', false], ['no', false]
    ].each do |from, to|

      it "should convert #{from.inspect} to #{to.inspect}" do
        h = {:key => from}
        h.sanitize!
        h[:key].should == to
      end
    end
  end

end

# EOF
