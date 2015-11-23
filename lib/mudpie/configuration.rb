require 'psych'

module MudPie
  class Configuration
    CONTENT_TYPE_FOR_EXT = {
      '.gif'  => 'image/gif',
      '.html' => 'text/html',
      '.jpeg' => 'image/jpeg',
      '.jpg'  => 'image/jpeg',
      '.png'  => 'image/png',
      '.text' => 'text/plain',
      '.txt'  => 'text/plain',
    }

    def initialize(path = nil)
      @config = Psych.load_file(path || 'mudpie.yml') || Hash.new
    end

    def content_type_for_extname(extname)
      CONTENT_TYPE_FOR_EXT[extname]
    end

    def index_name
      @config['index_name'] || 'index.html'
    end

    def path_to_pantry
      @config['pantry_path'] || '.mudpie/pantry.sqlite'
    end

    def path_to_source
      @config['source_path'] || 'source'
    end
  end

  def self.config
    @config ||= Configuration.new
  end
end
