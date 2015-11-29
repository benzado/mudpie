module MudPie
  class RenderContext
    attr_reader :pantry
    attr_reader :metadata

    def initialize(pantry)
      @pantry = pantry
      @metadata = Hash.new
    end

    def merge_metadata(hash)
      @metadata.merge!(hash)
      normalize_layout_value
    end

    def content_type!
      content_type or raise 'content_type undefined!'
    end

    def content_type
      @metadata['content_type']
    end

    def content_type=(mime_type)
      @metadata['content_type'] = mime_type
    end

    def normalize_layout_value
      layout = @metadata['layout']
      MudPie.logger.debug "normalizing layout value: #{layout.inspect}"
      case layout
      when Array
        layout.flatten!
      when String
        if layout.length > 0
          @metadata['layout'] = [ layout ]
        else
          @metadata['layout'] = []
        end
      when NilClass
        @metadata['layout'] = []
      else
        MudPie.logger.warn "ignoring unsupported layout value: #{layout.inspect}"
        @metadata['layout'] = []
      end
    end

    def needs_layout?
      ! @metadata['layout'].empty?
    end

    def next_layout_name
      @metadata['layout'].pop
    end

    def append_layout_name(layout_name)
      @metadata['layout'].push layout_name
    end
  end
end
