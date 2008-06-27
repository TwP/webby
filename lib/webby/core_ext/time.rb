
class Time

  def to_y
    self.to_yaml.slice(4..-1).strip
  end
end  # class Time

# EOF
