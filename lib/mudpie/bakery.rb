class MudPie::Bakery

  OUTPUT_ROOT = 'public'

  def self.target_path_for_source_path(source_path)
    MudPie::Renderer.strip_extensions(source_path.sub(%r{^pages}, OUTPUT_ROOT))
  end

  attr_reader :source_files, :target_files, :dependencies

  def initialize(source_files)
    @dependencies = Hash.new
    @source_files = source_files
    @target_files = Rake::FileList.new
    @source_files.each do |source_path|
      unless File.directory?(source_path)
        target_path = MudPie::Bakery.target_path_for_source_path(source_path)
        raise "#{source_path}: collision!" unless @dependencies[target_path].nil?
        @dependencies[target_path] = [source_path]
        @target_files.include(target_path)
      end
    end
  end

  def pantry
    unless @pantry
      @pantry = MudPie::Pantry.new(self)
      @source_files.each do |source_path|
        unless File.directory?(source_path)
          @pantry.stock(page_for_path(source_path))
        end
      end
    end
    return @pantry
  end

  def page_for_path(source_path)
    MudPie::Page.new(self, source_path)
  end

  def page_for_url(url)
    hsh = pantry.select(:select_page_by_url, url)
    MudPie::Page.new(self, hsh[:source_path]) if hsh
  end

  def bake(target_path)
    pantry
    puts "Baking #{target_path}"
    source_path = @dependencies[target_path].first
    page = page_for_path(source_path)
    FileUtils.mkpath(File.dirname(target_path))
    page.render_to(target_path)
  end

  def site
    @site ||= begin
      load 'site.rb'
      site = Object.new
      site.extend(::Site)
      site
    end
  end

  def serve_hot?
    @is_hot || false
  end

  def serve_hot!
    @is_hot = true
  end

  def layouts
    @layouts ||= begin
      Rake::FileList['layouts/**/*'].each_with_object(Hash.new) do |source_path, layouts|
        unless File.directory?(source_path)
          layout = MudPie::Layout.new(source_path)
          layouts[layout.name] = layout
          puts "Loading layout from #{source_path}"
        end
      end
    end
  end

  def layout_for_name(layout_name)
    layouts[layout_name.to_sym] || raise("Can't find layout named '#{layout_name}'!")
  end

  def reload_layouts
    @layouts = nil
  end

end
