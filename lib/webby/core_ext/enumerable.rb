
module Enumerable

  def injecting( initial )
    inject(initial) do |memo, obj|
      yield(memo, obj); memo
    end
  end
end  # module Enumerable

# EOF
