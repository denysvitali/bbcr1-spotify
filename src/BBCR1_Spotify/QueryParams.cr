class QueryParams
  @@params = {} of String => String

  def self.new(input : Hash(String, String))
    @@params = input
    return self
  end

  def self.to_s
    i = 0
    str = String.build do |str|
      @@params.each do |key, value|
        i += 1
        str << URI.escape(key)
        str << "="
        str << URI.escape(value)
        if i != @@params.size
          str << "&"
        end
      end
    end
  end
end
