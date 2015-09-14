require 'sqlite3'
require 'mudpie/loader'
require 'mudpie/resource'

module MudPie
  class Pantry
    def initialize(config = MudPie.config)
      @config = config
      open_or_create
    end

    def open_or_create
      @db = SQLite3::Database.new(@config.path_to_pantry)
      @db.execute %q{
        CREATE TABLE IF NOT EXISTS resources (
          id            INTEGER PRIMARY KEY,
          path          TEXT    NOT NULL UNIQUE,
          stocked_at    INTEGER,
          modified_at   INTEGER,
          source_length INTEGER,
          renderer      TEXT    NOT NULL,
          metadata_yaml BLOB,
          content       BLOB
        );
      }
    end

    def resources_insert
      @resources_insert ||= @db.prepare %q{
        INSERT OR REPLACE
          INTO resources (
            path,
            stocked_at,
            modified_at,
            source_length,
            renderer,
            metadata_yaml,
            content
          )
          VALUES (
            :path,
            :stocked_at,
            :modified_at,
            :source_length,
            :renderer,
            :metadata_yaml,
            :content
          );
      }
    end

    def stock(path)
      resource = MudPie::Loader.loader_for_path(path).load_resource
      resources_insert.execute(
        path: resource.path,
        stocked_at: Time.now.to_i,
        modified_at: path.mtime.to_i,
        source_length: path.size,
        renderer: resource.renderer_name,
        metadata_yaml: (resource.metadata_yaml.to_blob rescue nil),
        content: (resource.content.to_blob rescue nil)
      )
    end

    def each_resource
      select = @db.prepare('SELECT * FROM resources ORDER BY path ASC')
      results = select.execute
      while row = results.next_hash
        yield Resource.new(row)
      end
    end

    def resource_for_path(path)
      select = @db.prepare('SELECT * FROM resources WHERE path = ?')
      result_set = select.execute(path)
      row = result_set.next_hash
      Resource.new(row) unless row.nil?
    end
  end
end
