# $Id$

module Enumerable
  def injecting( initial )
    inject(initial) do |memo, obj|
      yield(memo, obj); memo
    end
  end
end

class Hash
  def sanitize!
    h = self.injecting({}) do |h, (k, v)|
          h[k] = case v
                 when 'none', 'nil'; nil
                 when 'true', 'yes'; true
                 when 'false', 'no'; false
                 else v end
        end
    self.replace h
  end

  def stringify_keys
    h = {}
    self.each {|k,v| h[k.to_s] = v}
    return h
  end

  def symbolize_keys
    h = {}
    self.each {|k,v| h[k.to_sym] = v}
    return h
  end
end

class String
  def underscore
    self.
      gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
      gsub(/([a-z\d])([A-Z])/,'\1_\2').
      tr(" -", "__").
      downcase
  end
end

# EOF
