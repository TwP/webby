
require ::File.expand_path(
    ::File.join(::File.dirname(__FILE__), %w[.. spec_helper]))

describe Time do

  it "should serialize to a YAML string" do
    now = Time.now

    utc_offset = now.utc_offset / 3600
    sign, utc_offset = utc_offset < 0 ? ['-', -utc_offset] : ['', utc_offset]
    str = "%s.%06d %s%02d:00" %
          [now.strftime('%Y-%m-%d %H:%M:%S'), now.usec, sign, utc_offset]

    now.to_y.should == str
  end
end

# EOF
