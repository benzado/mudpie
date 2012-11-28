require 'sqlite3'

class MudPie::Pantry

  DB_PATH = 'cache/pantry.sqlite'

  SQL = {
    :select_page_by_source_path => "SELECT * FROM `pages` WHERE `source_path` = ? LIMIT 1",
    :select_page_by_url => "SELECT `source_path` FROM `pages` WHERE `url` = ? LIMIT 1",
    :delete_meta_by_page_id => "DELETE `meta` WHERE `page_id` = ?"
  }

  def initialize(bakery)
    @bakery = bakery
    is_new = !File.exists?(DB_PATH)
    FileUtils.mkpath(File.dirname(DB_PATH)) if is_new
    @db = SQLite3::Database.new(DB_PATH)
    if is_new
      puts "Initializing pantry..."
      schema_path = File.join(File.dirname(__FILE__), 'pantry.sql')
      @db.execute_batch(File.read(schema_path))
    end
    @stmts = Hash.new do |hsh, sql|
      $stderr.puts "SQL: #{sql}"
      hsh[sql] = @db.prepare(SQL[sql] || sql)
    end
  end

  def select_all(sql, *args)
    results = []
    @stmts[sql].execute!(*args) do |row|
      hsh = Hash.new
      @stmts[sql].columns.each_with_index do |column, i|
        hsh[column.to_sym] = row[i]
      end
      results << hsh
    end
    return results
  end

  def select(sql, *args)
    select_all(sql, *args).first
  end

  def insert(table, hsh)
    keys = hsh.keys
    sql = "INSERT INTO `#{table}` ("
    sql << keys.map{ |k| "`#{k}`" }.join(',')
    sql << ") VALUES ("
    sql << (['?'] * keys.count).join(',')
    sql << ")"
    @stmts[sql].execute! *hsh.values_at(*keys)
    return @db.last_insert_row_id
  end

  def stock(page)
    file_mtime = File.mtime(page.source_path).to_i
    record = select(:select_page_by_source_path, page.source_path)
    if record
      return if file_mtime >= record[:mtime]
      @stmts[:delete_meta_by_page_id].execute!(record[:id])
    end
    puts "Stocking #{page.source_path}"
    @is_stocking = true
    @db.transaction do
      page_id = insert(:pages, {
        :source_path => page.source_path,
        :mtime => file_mtime,
        :url => page.url
      })
      page.meta.each do |key, value|
        if value.is_a?(Array)
          value.each_with_index do |v,i|
            insert(:meta, {
              :page_id => page_id,
              :key => key.to_s,
              :idx => i,
              :value => v.to_s
            })
          end
        else
          insert(:meta, {
            :page_id => page_id,
            :key => key.to_s,
            :value => (value.is_a?(Numeric) ? value : value.to_s)
          })
        end
      end
    end
    @is_stocking = false
  end

  def pages
    MudPie::PageQuery.new(self)
  end

  def execute_page_query(query)
    raise "Can't execute page query inside metadata." if @is_stocking
    sql = "SELECT `pages`.`source_path`"
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
    select_all(sql, *where_params).map do |hsh|
      @bakery.page_for_path(hsh[:source_path]).meta
    end
  end

end
