class Hash
  def stringify_keys
    inject({}) do |options, (key, value)|
      options[key.to_s] = value.to_s
      options
    end
  end
end