require 'pathname'
require 'mudpie/renderer'

module MudPie
  class Resource
    def initialize(row)
      @row = row.dup.freeze
    end

    def source_path
      Pathname.new @row['source_path']
    end

    def source_modified_at
      Time.at @row['source_modified_at']
    end

    def source_length
      @row['source_length']
    end

    def path
      @row['path']
    end

    def renderer_name
      @row['renderer_name']
    end

    def metadata_yaml
      @row['metadata_yaml']
    end

    def content
      @row['content']
    end

    def renderer
      MudPie::Renderer.renderer_class_for_name(renderer_name).new(self)
    end

    def metadata
      @metadata ||= Psych.load(metadata_yaml || '{}').freeze
    end

    def metadata_yaml_length
      metadata_yaml.length rescue 0
    end

    def content_length
      content.length rescue 0
    end

    # Allow a resource to be used as a Pathname
    alias_method :read, :content

    def up_to_date?
      (source_length == source_path.size) && (source_modified_at >= source_path.mtime)
    end

    def to_s
      "#<MudPie::Resource:#{path}>"
    end
  end
end
