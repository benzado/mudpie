module MudPie::Loader
  class Default < BasicLoader
    def self.can_load_path?(path)
      true # come at me, bro
    end

    def load_resource
      MudPie::Resource.new(
        'path'          => path,
        'renderer'      => 'default',
        'metadata_yaml' => nil,
        'content'       => source_path.read
      )
    end
  end

  add_loader_class Default
end
