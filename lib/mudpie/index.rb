module MudPie

class Index

  SELECT_FILES_SQL = 'SELECT `id`,`size`,`mtime`,`ymf_len`,`collection_name`,`url`,`date`,`path` FROM `files`'

  SQL = {
    :select_files => SELECT_FILES_SQL,
    :select_file_by_path => SELECT_FILES_SQL + ' WHERE `path` = ?',
    :select_file_by_url => SELECT_FILES_SQL + ' WHERE `url` = ?',
    :select_files_pages => SELECT_FILES_SQL + " WHERE `ymf_len` > 0 AND `path` NOT LIKE '~_%' ESCAPE '~'",
    :select_files_posts => SELECT_FILES_SQL + " WHERE `collection_name` = 'posts' ORDER BY `date` DESC",
    :select_files_md_key_value => SELECT_FILES_SQL + ' JOIN metadata ON metadata.file_id = files.id WHERE `key` = ? AND `value` = ? ORDER BY `date` DESC',
    :insert_file => 'INSERT INTO `files` (`size`,`mtime`,`ymf_len`,`collection_name`,`url`,`date`,`path`) VALUES (?,?,?,?,?,?,?)',
    :update_file => 'UPDATE `files` SET `size` = ?,`mtime` = ?,`ymf_len` = ?,`collection_name`=?,`url`=?,`date`=? WHERE `path` = ?',
    :delete_md => 'DELETE FROM `metadata` WHERE `file_id` = ?',
    :insert_md => 'INSERT INTO `metadata` (`file_id`,`key`,`index`,`value`) VALUES (?,?,?,?)',
    :select_md_file_key => 'SELECT `index`,`value` FROM `metadata` WHERE `file_id` = ? AND `key` = ? ORDER BY `index`',
    :select_md_file => 'SELECT `key`,`index`,`value` FROM `metadata` WHERE `file_id` = ? ORDER BY `key`,`index`',
    :select_md_values_for_key => 'SELECT `value` FROM metadata WHERE `key` = ? GROUP BY `value`'
  }

  def initialize(site)
    @site = site
    db_path = @site.config['index_path']
    is_new_db = ! (File.exists? db_path)
    @db = SQLite3::Database.new(db_path)
    if is_new_db then
      schema_root = File.dirname File.expand_path __FILE__
      puts "Initializing index with schema from #{schema_root}"
      sql = ""
      File.open(schema_root + '/index.sql', 'r').each_line do |line|
        sql << line
      end
      @db.execute_batch sql
    end
    @statements = {}
  end

  def statement(id)
    @statements[id] ||= @db.prepare(SQL[id])
  end

  def entry_from_row(row, path)
    entry = IndexEntry.new
    entry.path = path
    entry.id = row[0].to_i
    entry.size = row[1].to_i
    entry.mtime = row[2].to_i
    entry.ymf_len = row[3].to_i
    entry.collection_name = row[4]
    entry.url = row[5]
    entry.date = row[6].to_i
    return entry
  end

  def entry_for_path(path)
    entry = nil
    statement(:select_file_by_path).execute!(path) do |row|
      entry = entry_from_row row, path
    end
    entry
  end

  def save_entry(entry)
    statement(if entry.id.nil? then :insert_file else :update_file end).execute!(
      entry.size, entry.mtime, entry.ymf_len, entry.collection_name,
      entry.url, entry.date, entry.path
    )
    if entry.id.nil? then
      entry.id = @db.last_insert_row_id
    else
      statement(:delete_md).execute!(entry.id)
    end
  end

  def save_ymf_data(file_id, data)
    data.each_pair do |key,value|
      if value.is_a? Array then
        value.each_index do |i|
          statement(:insert_md).execute!(file_id, key, i, value[i])
        end
      elsif value.is_a? Hash then
        puts "WARNING: YAML key `#{key}`: hashes not searchable."
      elsif value.is_a? TrueClass then
        statement(:insert_md).execute!(file_id, key, nil, 1)
      elsif value.is_a? FalseClass then
        statement(:insert_md).execute!(file_id, key, nil, 0)
      else
        statement(:insert_md).execute!(file_id, key, nil, value)
      end
    end
  end

  def update_file(path)
    previous_entry = entry_for_path path
    size = (File.size path)
    mtime = (File.mtime path).to_i
    return if up_to_date?(previous_entry, mtime, size)
    file = SourceFile.new(path)
    return if file.ymf_data['published'] === false
    if previous_entry then
      puts "Updating #{path}"
    else
      puts "Adding #{path}"
    end
    entry = IndexEntry.new
    entry.id = previous_entry.id unless previous_entry.nil?
    entry.path = path
    entry.size = size
    entry.mtime = mtime
    entry.ymf_len = file.ymf_len
    entry.url = @site.url_for_page(file)
    entry.date = (@site.date_for_page(file)).to_i
    entry.collection_name = @site.collection_name_for_page(file)
    save_entry entry
    save_ymf_data entry.id, file.ymf_data
  end

  def up_to_date?(entry, mtime, size)
    entry != nil && entry.mtime == mtime && entry.size == size
  end

  def page_for_url(url)
    page = nil
    statement(:select_file_by_url).execute!(url) do |row|
      entry = entry_from_row row, row[7]
      page = Page.new(@site, entry)
    end
    page
  end

  # unused
  def ymf_data_for_file_id(id)
    ymf_data = {}
    statement(:select_md_file).execute!(file_id) do |row|
      key = row[0]
      index = row[1]
      value = row[2]
      if index.nil? then
        ymf_data[key] = value
      elsif index == 0 then
        ymf_data[key] = [value]
      else
        ymf_data[key] << value
      end
    end
    ymf_data
  end

  # unused
  def ymf_value_for_file_id_and_key(id, key)
    values = []
    statement(:select_md_file_key).execute!(file_id, key) do |row|
      index = row[0]
      value = row[1]
      return value if index.nil?
      values << value
    end
    if values.length > 0 then
      values
    else
      nil
    end
  end

  def each(stmt = nil)
    (stmt || statement(:select_files)).execute! do |row|
      entry = entry_from_row row, row[7]
      yield Page.new(@site, entry)
    end
  end

  def all(stmt = nil)
    pages = []
    self.each(stmt) { |page| pages << page }
    pages
  end

  def all_pages
    all statement(:select_files_pages)
  end

  def all_posts
    all statement(:select_files_posts)
  end

  def all_for_key_and_value(key, value)
    stmt = statement(:select_files_md_key_value)
    stmt.bind_param 1, key
    stmt.bind_param 2, value
    all stmt
  end

  def all_known_values_for_key(key)
    values = []
    statement(:select_md_values_for_key).execute!(key) do |row|
      values << row[0]
    end
    values
  end

  def all_posts_by_value_for_key(key)
    collection = []
    (all_known_values_for_key key).each do |value|
      collection << [value, PageSet.new(self, key, value)]
    end
    collection
  end

  def all_posts_by_category
    all_posts_by_value_for_key 'category'
  end

  def all_posts_by_tag
    all_posts_by_value_for_key 'tags'
  end

end

end # module
