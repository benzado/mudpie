module MudPie

class SourceFile

  attr_reader :path

  def initialize(path, ymf_len = nil)
    @path = path
    @ymf_len = ymf_len
  end

  def ymf_len
    @ymf_len ||= begin
      f = File.open(path, 'r')
      if f.readline == "---\n" then
        while f.readline != "---\n" do end
        f.tell
      else
        0
      end
    end
  end

  def ymf_data
    @ymf_data ||= if ymf_len > 0 then
      YAML.parse_file(@path).transform || {}
    else
      {}
    end
  end

  def raw_content
    if ymf_len == 0 then
      File.read @path
    else
      f = File.open(@path, 'r')
      f.seek ymf_len
      f.read
    end
  end

  # for subclasses that define @site

  def layout
    @layout ||= if name = ymf_data['layout'] then
      @site.layout name
    end
  end

  def to_liquid
    self
  end

  def has_key?(key)
    ymf_data.has_key?(key) || (layout && layout.has_key?(key))
  end

  def [](key)
    ymf_data[key] || (layout && layout[key])
  end

end

end # module
