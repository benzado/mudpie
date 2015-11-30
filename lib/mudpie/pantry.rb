require 'sqlite3'
require 'mudpie/khatba_enumerator'
require 'mudpie/loader'
require 'mudpie/logger'
require 'mudpie/resource'

module MudPie
  class Pantry
    RESOURCE_COLUMNS = {
      source_path:        'TEXT    NOT NULL UNIQUE',
      source_modified_at: 'INTEGER NOT NULL',
      source_length:      'INTEGER NOT NULL',
      path:               'TEXT    NOT NULL UNIQUE',
      renderer_name:      'TEXT    NULL',
      metadata_yaml:      'BLOB',
      content:            'BLOB',
    }

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
      column_defs = RESOURCE_COLUMNS.map{ |n,t| "#{n} #{t}" }.join(',')
      @db.execute %Q{
        CREATE TABLE IF NOT EXISTS resources (#{column_defs});
        PRAGMA application_id = 0x4d755069; -- MuPi
        PRAGMA user_version = 4;
      }
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
      # Replacing the path separator (/) with NULL results in a depth-first
      # sort order, which is useful when comparing to the file system.
      select_all = @db.prepare %q(
        SELECT * FROM resources ORDER BY REPLACE(source_path,'/',CHAR(0))
      )
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

    def stock
      source_paths_and_resources.each do |source_path, resource|
        if source_path.nil?
          logger.warn "Deleting #{resource.source_path}"
          delete_resource resource
        elsif resource.nil?
          if @config.ignore_source_path?(source_path)
            logger.debug "Ignoring #{source_path}"
          else
            create_resource source_path
          end
        else
          if @config.ignore_source_path?(source_path)
            logger.warn "Deleting #{resource.source_path}"
            delete_resource resource
          else
            update_resource(source_path, resource)
          end
        end
      end
    end

    private

    def logger
      MudPie.logger
    end

    def source_paths_and_resources
      source_paths = Pathname.new(@config.path_to_source).find
      KhatbaEnumerator.new(source_paths, resources) do |source_path, resource|
        source_path.to_s <=> resource.source_path.to_s
      end
    end

    def create_resource(source_path)
      if loader = MudPie::Loader.loader_for_path(source_path)
        logger.info "Stocking #{source_path}"
        resource = loader.load_resource
        resources_insert_statement.execute(
          source_path: source_path.to_s,
          source_modified_at: source_path.mtime.to_i,
          source_length: source_path.size,
          path: resource.path,
          renderer_name: resource.renderer_name,
          metadata_yaml: (resource.metadata_yaml.to_blob rescue nil),
          content: (resource.content.to_blob rescue nil)
        )
      elsif source_path.directory?
        return
      else
        logger.fatal "No loader for path: #{source_path}"
      end
    end

    def delete_resource(resource)
      resources_delete_statement.execute(resource.path)
    end

    def update_resource(source_path, resource)
      if resource.up_to_date?
        logger.debug "Skipping #{resource.source_path} (up-to-date)"
      else
        delete_resource resource
        create_resource source_path
      end
    end

    def resources_insert_statement
      @resources_insert_statement ||= begin
        column_names = RESOURCE_COLUMNS.keys.join(',')
        value_names = RESOURCE_COLUMNS.keys.map{ |k| ":#{k}" }.join(',')
        @db.prepare %Q(
          INSERT OR REPLACE
            INTO resources (#{column_names})
            VALUES (#{value_names});
        )
      end
    end

    def resources_delete_statement
      @resources_delete_statement ||= begin
        @db.prepare %q(DELETE FROM resources WHERE path = ?)
      end
    end

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
