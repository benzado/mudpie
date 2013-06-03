require 'sqlite3'

class MudPie::Pantry

  class DuplicateURLError < StandardError
    def initialize(source_path, url)
      super("CONFLICT: Cannot stock file '#{source_path}' because the URL it maps to ('#{url}') is already used by another file.")
    end
  end

  DB_PATH = Pathname.new('cache/pantry.sqlite')

  attr_reader :bakery

  def initialize(bakery)
    @bakery = bakery
    is_new = !DB_PATH.exist?
    DB_PATH.dirname.mkpath if is_new
    @db = SQLite3::Database.new(DB_PATH.to_s)
    if is_new
      puts "Initializing pantry..."
      schema_path = File.join(MudPie::GEM_ROOT, 'rsrc/pantry.sql')
      @db.execute_batch(File.read(schema_path))
    end
    @stmts = Hash.new do |hsh, sql|
      if MudPie::OPTIONS[:debug]
        $stderr.puts "SQL: #{sql}"
        @db.execute2("EXPLAIN QUERY PLAN #{sql}") do |line|
          $stderr.printf("  %8s %5s %4s %s\n", *line)
        end
      end
      hsh[sql] = @db.prepare(sql)
    end
  end

  def stock(source_path, url, meta)
    @is_stocking = true
    @db.transaction do
      page_id = page_id_for_source_path(source_path)
      if page_id
        @stmts["DELETE FROM `meta` WHERE `page_id` = ?"].execute!(page_id)
        @stmts["UPDATE `pages` SET `mtime` = ? WHERE `id` = ?"].execute!(source_path.mtime.to_i, page_id)
      else
        page_id = insert_page(source_path, url)
      end
      meta.each do |key, value|
        insert_meta(page_id, key, value)
      end
    end
  rescue SQLite3::ConstraintException => e
    if e.message == 'column url is not unique'
      raise DuplicateURLError.new(source_path, url)
    else
      raise e
    end
  ensure
    @is_stocking = false
  end

  def load_meta_for_page_id(context, page_id, allow_overwrites = false)
    select_all("SELECT * FROM `meta` WHERE `page_id` = ? ORDER BY `idx`", page_id) do |row|
      begin
        value = case row[:type]
        when 'Symbol' then row[:value].to_sym
        when 'Boolean' then row[:value] != nil
        when 'Time' then Time.at(row[:value].to_i)
        when nil then row[:value]
        else raise "Pantry contains unknown type '#{row[:type]}'"
        end
      rescue TypeError => e
        raise "#{e.message}: #{row.inspect}"
      end
      key = row[:key]
      idx = row[:idx]
      if idx.nil?
        raise "Cannot overwrite #{key}" unless context[key].nil? || allow_overwrites
        context[key] = value
      elsif idx == 0
        raise "Cannot overwrite #{key}" unless context[key].nil? || allow_overwrites
        context[key] = [value]
      else
        raise "Problem 2" if context[key].length != idx
        context[key] << value
      end
    end
  end

  def execute_page_query(query)
    raise "Can't execute page query inside metadata section." if @is_stocking
    sql = "SELECT `pages`.*"
    query.keys.each do |key|
      sql << ",`t_#{key}`.`value` AS `#{key}`"
    end
    sql << " FROM `pages` "
    query.keys.each do |key|
      sql << "LEFT JOIN `meta` AS `t_#{key}` ON (`t_#{key}`.`page_id` = `pages`.`id` AND `t_#{key}`.`key` = '#{key}') "
    end
    where_sql, *where_params = query.where_sql
    sql << where_sql
    sql << " GROUP BY `pages`.`source_path` "
    sql << query.order_sql
    select_all(sql, *where_params).map do |row|
      MudPie::Page.new(self, row).meta
    end
  end

  def pages
    MudPie::PageQuery.new(self)
  end

  def mtime_for_path(path)
    select("SELECT `mtime` FROM `pages` WHERE `source_path` = ? LIMIT 1", path.to_s) do |row|
      Time.at(row[:mtime])
    end
  end

  def each_path
    select_all("SELECT `id`, `source_path` FROM `pages`") do |row|
      yield Pathname.new(row[:source_path]), row[:id]
    end
  end

  # Note that this method does not include layouts.
  def each_page
    select_all("SELECT * FROM `pages` WHERE `url` LIKE '/%'") do |row|
      yield MudPie::Page.new(self, row)
    end
  end

  def page_for_url(url)
    select("SELECT * FROM `pages` WHERE `url` = ?", url) do |row|
      MudPie::Page.new(self, row)
    end
  end

  def layout_for_name(name)
    select("SELECT * FROM `pages` WHERE `url` = ? LIMIT 1", "##{name}") do |row|
      MudPie::Page.new(self, row)
    end
  end

  def delete_pages_by_id(ids_to_purge)
    id_list = ids_to_purge.join(',')
    @db.execute("DELETE FROM `pages` WHERE `id` IN (#{id_list})")
    @db.execute("DELETE FROM `meta` WHERE `page_id` IN (#{id_list})")
  end

  private

  # SELECT Helper Functions

  def page_id_for_source_path(path)
    select("SELECT * FROM `pages` WHERE `source_path` = ? LIMIT 1", path.to_s) { |row| row[:id].to_i }
  end

  # INSERT Helper Functions

  def insert_page(source_path, url)
    insert :pages, source_path: source_path.to_s, mtime: source_path.mtime.to_i, url: url
  end

  def insertable_value(value)
    case value
    when String, Numeric, NilClass
      [value, nil]
    when Symbol
      [value.to_s, 'Symbol']
    when TrueClass
      [1, 'Boolean']
    when FalseClass
      [nil, 'Boolean']
    when Time
      [value.to_i, 'Time']
    else
      raise "Cannot store <#{value.class}:#{value}> in pantry!"
    end
  end

  def insert_meta(page_id, key, value)
    k = key.to_s
    if value.is_a? Array
      value.each_with_index do |element, i|
        v, t = insertable_value(element)
        insert :meta, page_id: page_id, key: k, idx: i, value: v, type: t
      end
    else
      v, t = insertable_value(value)
      insert :meta, page_id: page_id, key: k, value: v, type: t
    end
  end

  # Basic Database Operations

  def select_all(sql, *args)
    results = []
    @stmts[sql].execute!(*args) do |row|
      hsh = Hash.new
      @stmts[sql].columns.each_with_index do |column, i|
        hsh[column.to_sym] = row[i]
      end
      yield hsh if block_given?
      results << hsh
    end
    return results
  end

  def select(sql, *args)
    row = select_all(sql, *args).first
    if block_given?
      yield row if row
    else
      row
    end
  end

  def insert(table, hsh)
    keys = hsh.keys
    sql = "INSERT INTO `#{table}` ("
    sql << keys.map{ |k| "`#{k}`" }.join(',')
    sql << ") VALUES ("
    sql << (['?'] * keys.count).join(',')
    sql << ")"
    @stmts[sql].execute!(*hsh.values_at(*keys))
    return @db.last_insert_row_id
  end

end
