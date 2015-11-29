require 'sqlite3'
require 'mudpie/resource'

module MudPie
  class Pantry
    def initialize(config = MudPie.config)
      @config = config
      open_or_create
    end

    def open_or_create
      @db = SQLite3::Database.new(@config.path_to_pantry)
      @db.define_function('YAML_GET') do |yaml_blob, key|
        if yaml_blob
          begin
            object = Psych.load(yaml_blob)
            result = object[key].to_s # TODO: What types are OK to return?
            MudPie.logger.debug("YAML_GET(..., #{key.inspect}) => #{result.inspect}")
            result
          rescue Psych::SyntaxError => e
            MudPie.logger.warn "cannot parse #{yaml_blob.inspect}: #{e.message}"
            nil
          end
        end
      end
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

    def stock_resource_from_source(resource, source)
      resources_insert.execute(
        path: resource.path,
        stocked_at: Time.now.to_i,
        modified_at: source.mtime.to_i,
        source_length: source.size,
        renderer: resource.renderer_name,
        metadata_yaml: (resource.metadata_yaml.to_blob rescue nil),
        content: (resource.content.to_blob rescue nil)
      )
    end

    def resource_for_path(path)
      select = @db.prepare('SELECT * FROM resources WHERE path = ?')
      # I don't know why, but this query fails when the path is encoded as
      # ASCII_8BIT even when all the strings involved are ASCII-compatible.
      results = select.execute(path.encode(Encoding::UTF_8))
      row = results.next_hash
      Resource.new(row) unless row.nil?
    end

    def resources
      select_all = @db.prepare('SELECT * FROM resources ORDER BY path ASC')
      resources_from_results(select_all.execute)
    end

    def resources_for_sql(sql_clause, bind_values)
      sql = "SELECT * FROM resources" + sql_clause
      MudPie.logger.debug "Executing SQL: #{sql}"
      results = @db.prepare(sql).execute(bind_values)
      resources_from_results(results)
    end

    # TODO: allow some metadata to be "indexed" (that is, stored in their own
    #       columns; this method would return the column name in those cases.
    def sql_for_key(key)
      quoted_key = SQLite3::Database.quote(key)
      "YAML_GET(metadata_yaml, '#{quoted_key}')"
    end

    private

    def resources_from_results(results)
      Enumerator.new do |caller|
        while row = results.next_hash
          caller.yield Resource.new(row)
        end
        results.close
      end
    end
  end
end
