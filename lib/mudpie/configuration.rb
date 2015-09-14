require 'psych'

module MudPie
  class Configuration
    def initialize(path = nil)
      @config = Psych.load_file(path || 'pie.yml') || Hash.new
    end

    def path_to_pantry
      @config['pantry'] || '.mudpie/pantry.sqlite'
    end
  end

  def self.config
    @config ||= Configuration.new
  end
end
