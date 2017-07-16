require 'psych'

module MudPie
  class Configuration
    CONTENT_TYPE_FOR_EXT = {
      '.css'  => 'text/css; charset=UTF-8',
      '.gif'  => 'image/gif',
      '.gif'  => 'image/gif',
      '.html' => 'text/html; charset=UTF-8',
      '.ico'  => 'image/x-icon',
      '.jpeg' => 'image/jpeg',
      '.jpeg' => 'image/jpeg',
      '.jpg'  => 'image/jpeg',
      '.jpg'  => 'image/jpeg',
      '.js'   => 'application/javascript', # old IE needs text/javascript
      '.json' => 'application/json',
      '.pdf'  => 'application/pdf',
      '.pl'   => 'text/plain; charset=UTF-8',
      '.plist'=> 'application/x-plist',
      '.png'  => 'image/png',
      '.rtf'  => 'text/rtf',
      '.safariextz' => 'application/octet-stream',
      '.text' => 'text/plain; charset=UTF-8',
      '.txt'  => 'text/plain; charset=UTF-8',
      '.xml'  => 'application/xml',
      '.zip'  => 'application/zip',
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

    def ignore_source_path?(path)
      path.fnmatch('**/.DS_Store')
    end
  end

  def self.config
    @config ||= Configuration.new
  end
end
