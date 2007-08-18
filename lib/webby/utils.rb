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
                 when 'none', 'nil': nil
                 when 'true', 'yes': true
                 when 'false', 'no': false
                 else v end
        end
    self.replace h
  end
end

# EOF
