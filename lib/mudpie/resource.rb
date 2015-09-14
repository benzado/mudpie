module MudPie
  class Resource
    def initialize(row)
      @row = row.dup.freeze
    end

    def path
      @row['path']
    end

    def modified_at
      Time.at @row['modified_at']
    end

    def stocked_at
      Time.at @row['stocked_at']
    end

    def renderer_name
      @row['renderer']
    end

    def renderer
      MudPie::Renderer.renderer_class_for_name(renderer_name).new(self)
    end

    def metadata_yaml
      @row['metadata_yaml']
    end

    def metadata
      @metadata ||= Psych.load(metadata_yaml || '{}').freeze
    end

    def content
      @row['content']
    end

    def metadata_yaml_length
      metadata_yaml.length rescue 0
    end

    def content_length
      content.length rescue 0
    end
  end
end
