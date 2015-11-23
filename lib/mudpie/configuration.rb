require 'psych'

module MudPie
  class Configuration
    CONTENT_TYPE_FOR_EXT = {
      '.css'  => 'text/css',
      '.gif'  => 'image/gif',
      '.html' => 'text/html',
      '.jpeg' => 'image/jpeg',
      '.jpg'  => 'image/jpeg',
      '.js'   => 'application/javascript', # old IE needs text/javascript
      '.png'  => 'image/png',
      '.text' => 'text/plain',
      '.txt'  => 'text/plain',
      '.xml'  => 'application/xml',
    }

    def initialize(path = nil)
      @config = Psych.load_file(path || 'mudpie.yml') || Hash.new
    end

    def content_type_for_extname(extname)
      CONTENT_TYPE_FOR_EXT[extname] || begin
        MudPie.logger.warn "No Content-Type defined for #{extname}"
        'application/octet-stream'
      end
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
