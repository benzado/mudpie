module MudPie::Loader
  class Default < BasicLoader
    def self.can_load_path?(path)
      path.file?
    end

    def load_resource
      MudPie::Resource.new(
        'path'          => path,
        'renderer_name' => 'default',
        'metadata_yaml' => nil,
        'content'       => source_path.read
      )
    end
  end

  add_loader_class Default
end
