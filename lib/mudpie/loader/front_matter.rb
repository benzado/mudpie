module MudPie::Loader
  class FrontMatter < BasicLoader
    RENDERER_FOR_TYPE = {
      '.erb'      => 'erb',
      '.markdown' => 'markdown',
      '.md'       => 'markdown',
      '.textile'  => 'textile',
    }

    def self.can_load_path?(path)
      RENDERER_FOR_TYPE.has_key?(path.extname)
    end

    def path
      super.chomp(source_path.extname)
    end

    def renderer
      RENDERER_FOR_TYPE[source_path.extname]
    end

    def load_resource
      yaml = nil
      content = source_path.read

      %r{^---\r?\n(.*?)\n---\r?\n}m.match(content) do |m|
        yaml = m[1]
        content = m.post_match
      end

      MudPie::Resource.new(
        'path' => path,
        'renderer_name' => renderer,
        'metadata_yaml' => yaml,
        'content' => content
      )
    end
  end

  add_loader_class FrontMatter
end
