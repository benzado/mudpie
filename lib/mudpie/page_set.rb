module MudPie

class PageSet

  def initialize(index, key, value)
    @index = index
    @key = key
    @value = value
  end

  def pages
    @pages ||= @index.all_for_key_and_value @key, @value
  end

  def to_liquid
    pages
  end

end

end # module
