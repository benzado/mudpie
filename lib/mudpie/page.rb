module MudPie

class Page < SourceFile

  def initialize(site, entry)
    @site = site
    @entry = entry
    super(entry.path, entry.ymf_len)
  end

  def url
    @entry.url
  end

  def collection_name
    @entry.collection_name
  end

  def format_proc
    name = ymf_data['filter']
    if name && !Formats.has_key?('.' + name) then
      puts "WARNING: filter `#{name}` not found"
    end
    Formats[name || (File.extname @path)]
  end

  def add_dependency(path)
    @site.index.add_dependency(@entry.id, path)
  end

  def dependencies
    [ @path ] + @site.index.dependencies(@entry.id)
  end

  def needs_render?(dst_path)
    if File.exists? dst_path then
      dst_time = File.mtime dst_path
      dependencies.any? { |dep_path| File.mtime(dep_path) > dst_time }
    else
      true
    end
  end

  def render_to(dst_path)
    @site.index.clear_dependencies(@entry.id)
    if ymf_len == 0 then
      # File has no YMF, so just do a straight copy.
      puts "Copying #{dst_path}"
      begin
        FileUtils.cp @path, dst_path
        File.utime(@entry.mtime, @entry.mtime, dst_path)
      rescue => e
        puts "ERROR: #{e}"
      end
    else
      puts "Rendering #{dst_path}"
      content = rendered_content
      File.open(dst_path, 'w') do |f|
        f.write content
      end
      newtime = dependencies.map{ |p| File.mtime p }.max
      File.utime(newtime, newtime, dst_path)
    end
  end

  def rendered_content(embed_in_layout = true)
    if ymf_len == 0 then
      File.read @path
    else
      # Step 1: run it through liquid
      template = Liquid::Template.parse raw_content
      content = begin
        context = { 'site' => @site, 'page' => self }
        template.render!(context, { :filters => [MudPie::Filters] })
      rescue => e
        puts "Liquid Exception: #{e.message} in page #{@path}"
        puts "  " + e.backtrace.join("\n  ")
      end
      # Step 2: filter if necessary
      content = format_proc.call self, content
      # Step 3: render layout (optional)
      if embed_in_layout && layout then
        layout.render context.merge('content' => content)
      else
        content
      end
    end
  end

  # Liquid Template access
  # for pages: url, content
  # for posts: title, url, date, id, categories, tags, content

  def generated_title
    filename = File.basename @path
    if m = /^(\d+-\d+-\d+-)?([^.]+)/.match(filename) then
      title = m[2]
    else
      title = filename[0,(filename.index '.')]
    end
    title.gsub!(/-+/, ' ').gsub!(/^\S|\s\S/) {|x| x.upcase }
  end

  def to_liquid
    self
  end

  BUILTIN_KEYS = %w[content date id title url]

  def has_key?(key)
    BUILTIN_KEYS.include?(key) || super(key)
  end

  def [](key)
    case key
    when 'content'
      rendered_content false
    when 'date'
      Time.at @entry.date
    when 'id'
      ymf_data['id'] || @entry.url
    when 'title'
      ymf_data['title'] || generated_title
    when 'url'
      @entry.url
    else
      super(key)
    end
  end

end

end # module
