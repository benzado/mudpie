module MudPie::Layout
  LAYOUT_CLASS_FOR_EXTNAME = Hash.new

  class BasicLayout
    def initialize(path)
      raise "`initialize` not implemented by #{self.class.name}"
    end

    def render(context, content)
      raise "`render` not implemented by #{self.class.name}"
    end
  end

  def self.find_by_name(layout_name)
    layout_paths = Pathname.glob("layout/#{layout_name}.*")
    if layout_paths.empty?
      raise "layout '#{layout_name}' not found"
    end
    if layout_paths.count > 1
      raise "multiple files for layout name '#{layout_name}': #{layout_paths}"
    end
    layout_path = layout_paths.first
    layout_class = LAYOUT_CLASS_FOR_EXTNAME[layout_path.extname]
    if layout_class.nil?
      raise "unsupported layout type at #{layout_path}"
    end
    layout_class.new(layout_path)
  end

  def self.add_layout_class(ext, layout_class)
    LAYOUT_CLASS_FOR_EXTNAME[ext] = layout_class
  end
end

require 'mudpie/layout/erb'
