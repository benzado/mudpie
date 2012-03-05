module MudPie

class SourceFile

  def self.ymf_len(path)
    f = File.open(path, 'r')
    if f.readline == "---\n" then
      while f.readline != "---\n" do end
      f.tell
    else
      0
    end
  end

  attr_reader :path

  def initialize(path, ymf_len = nil)
    @path = path
    @ymf_len = ymf_len
  end

  def ymf_len
    @ymf_len || (@ymf_len = SourceFile.ymf_len @path)
  end

  def load_ymf_data
    if ymf_len > 0 then
      YAML.parse_file(@path).transform || {}
    else
      {}
    end
  end

  def ymf_data
    @ymf_data || (@ymf_data = load_ymf_data)
  end

  def raw_content
    skip = self.ymf_len
    if skip == 0 then
      File.read @path
    else
      f = File.open(@path, 'r')
      f.seek skip
      f.read
    end
  end

end

end # module
