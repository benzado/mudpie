require 'sqlite3'
require 'mudpie/loader'
require 'mudpie/resource'

module MudPie
  class Pantry
    def initialize(config)
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
      select = @db.prepare('SELECT * FROM resources WHERE path GLOB ?')
      # Enclosing special characters in square brackets instructs GLOB to
      # treat them as regular characters to be matched.
      escaped_path = path.gsub(/[\*\?\[\]]/) { |c| "[#{c}]" }
      result_set = select.execute(escaped_path + '*')

      first_hash = result_set.next_hash
      return nil if first_hash.nil?

      second_hash = result_set.next_hash
      return Resource.new(first_hash) if second_hash.nil?

      matched_resource_paths = [ first_hash['path'], second_hash['path'] ]
      result_set.each_hash do |row_hash|
        matched_resource_paths << row_hash['path']
      end
      raise "path #{path} is ambiguous, matches #{matched_resource_paths.count} resources: #{matched_resource_paths.inspect}"
    end
  end
end
