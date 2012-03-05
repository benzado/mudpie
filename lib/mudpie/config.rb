module MudPie

class Config

  DEFAULTS = {
    'collections' => ['_posts'],
    'destination' => '_site~mp',
    'exclude' => ['.DS_Store', '.git', '.gitignore'],
    'includes_root' => '_includes',
    'index_path' => '_index.db',
    'layouts_root' => '_layouts',
    'permalink' => '/:categories/:year/:month/:day/:title.html',
    'server_port' => 3000
  }

  def initialize(rel_path)
    # path may be a directory or a config file
    path = File.expand_path rel_path
    if File.directory? path then
      src_root = path
      config_path = File.join(path, '_config.yml')
    else
      src_root = File.dirname path
      config_path = path
    end
    @STORE = DEFAULTS.clone
    @STORE['source'] = src_root # a dynamic default
    if File.file? config_path then
      puts "Loading configuration from #{config_path}"
      @STORE.merge!(YAML.parse_file(config_path).transform)
      @STORE['exclude'] << '.git'
    end
    Dir.chdir self['source']
    puts "Working from directory #{Dir.pwd}"
  end

  def has_key?(key)
    @STORE.has_key? key
  end

  def [](key)
    if @STORE.has_key? key then
      @STORE[key]
    else
      throw "Unknown configuration key '#{key}'"
    end
  end

  def to_s
    @STORE.inspect
  end

end

end # module
