module MudPie

class Index

	SELECT_FILES_SQL = 'SELECT `id`,`size`,`mtime`,`ymf_len`,`collection_name`,`url`,`date`,`path` FROM `files`'

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
		@files_select = @db.prepare(SELECT_FILES_SQL + ' WHERE `path` = ?')
		@files_insert = @db.prepare('INSERT INTO `files` (`size`,`mtime`,`ymf_len`,`collection_name`,`url`,`date`,`path`) VALUES (?,?,?,?,?,?,?)')
		@files_update = @db.prepare('UPDATE `files` SET `size` = ?,`mtime` = ?,`ymf_len` = ?,`collection_name`=?,`url`=?,`date`=? WHERE `path` = ?')
		@md_delete = @db.prepare('DELETE FROM `metadata` WHERE `file_id` = ?')
		@md_insert = @db.prepare('INSERT INTO `metadata` (`file_id`,`key`,`index`,`value`) VALUES (?,?,?,?)')
		@md_select_file_key = @db.prepare('SELECT `index`,`value` FROM `metadata` WHERE `file_id` = ? AND `key` = ? ORDER BY `index`')
		@md_select_file = @db.prepare('SELECT `key`,`index`,`value` FROM `metadata` WHERE `file_id` = ? ORDER BY `key`,`index`')
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
		@files_select.execute!(path) do |row|
			entry = entry_from_row row, path
		end
		entry
	end

	def save_entry(entry)
		if entry.id.nil? then @files_insert else @files_update end.execute!(
			entry.size, entry.mtime, entry.ymf_len, entry.collection_name,
			entry.url, entry.date, entry.path
		)
		if entry.id.nil? then
			entry.id = @db.last_insert_row_id
		else
			@md_delete.execute!(entry.id)
		end
	end

	def save_ymf_data(file_id, data)
		data.each_pair do |key,value|
			if value.is_a? Array then
				value.each_index do |i|
					@md_insert.execute!(file_id, key, i, value[i])
				end
			elsif value.is_a? Hash then
				puts "WARNING: #{path}: YAML key `#{key}`: hashes not supported."
			else
				@md_insert.execute!(file_id, key, nil, value)
			end
		end
	end

	def update_file(path)
		previous_entry = entry_for_path path
		size = (File.size path)
		mtime = (File.mtime path).to_i
		return if up_to_date?(previous_entry, mtime, size)
		if previous_entry then
			puts "Updating #{path}"
		else
			puts "Adding #{path}"
		end
		file = SourceFile.new(path)
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
		stmt = @db.prepare(SELECT_FILES_SQL + ' WHERE `url` = ?')
		stmt.execute!(url) do |row|
			entry = entry_from_row row, row[7]
			page = Page.new(@site, entry)
		end
		page
	end

	# unused
	def ymf_data_for_file_id(id)
		ymf_data = {}
		@md_select_file.execute!(file_id) do |row|
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
		@md_select_file_key.execute!(file_id, key) do |row|
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
		if stmt.nil? then
			stmt = @db.prepare(SELECT_FILES_SQL)
		end
		stmt.execute! do |row|
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
		where = " WHERE `ymf_len` > 0 AND `path` NOT LIKE '~_%' ESCAPE '~'"
		all @db.prepare(SELECT_FILES_SQL + where)
	end

	def all_posts
		where = " WHERE `collection_name` = 'posts' ORDER BY `date` DESC"
		all @db.prepare(SELECT_FILES_SQL + where)
	end

	def all_for_key_and_value(key, value)
		join_sql = ' JOIN metadata ON metadata.file_id = files.id'
		where_sql = ' WHERE `key` = ? AND `value` = ? ORDER BY `date` DESC'
		stmt = @db.prepare(SELECT_FILES_SQL + join_sql + where_sql)
		stmt.bind_param 1, key
		stmt.bind_param 2, value
		all stmt
	end

	def all_known_values_for_key(key)
		values = []
		query = 'SELECT `value` FROM metadata WHERE `key` = ? GROUP BY `value`'
		@db.execute(query, key) do |row|
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
