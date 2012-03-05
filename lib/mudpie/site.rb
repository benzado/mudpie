module MudPie

class Site

	def initialize(config)
		@config = config
		@index = Index.new(self)
		@layouts = {}
		@time = Time.new
	end

	def config
		@config
	end

	def index
		@index
	end

	def layout(name)
		@layouts[name] || (@layouts[name] = Layout.new(self, name))
	end

	def update_index
		index_dir nil
	end

	def index_dir(dir)
		Dir.foreach(dir || '.') do |name|
			next if name == '.' or name == '..'
			next if @config['exclude'].include? name
			if name[0,1] == '_' then
				next unless @config['collections'].include? name
			end
			path = if dir.nil? then name else File.join(dir, name) end
			if File.directory? path then
				index_dir path
			else
				index_file path
			end
		end
	end

	def index_file(path)
		@index.update_file(path)
	end

	POST_FILENAME_PATTERN = %r{^(\d{4}-\d{1,2}-\d{2})-([^.]+)}

	def date_for_page(page)
		date_text = page.ymf_data['date']
		return Time.parse date_text unless date_text.nil?
		m = POST_FILENAME_PATTERN.match(File.basename page.path)
		return Time.parse m[1].to_s if m
		File.mtime page.path
	end

	def slug_for_page(page)
		slug = page.ymf_data['slug']
		return slug unless slug.nil?
		m = POST_FILENAME_PATTERN.match(File.basename page.path)
		return m[2].to_s if m
		title = page.ymf_data['title']
		title.downcase.gsub(/[^a-z0-9 ]/, '').gsub(/\s+/, '-') if title
		name = File.basename @path
		i = (name.rindex '.') || name.length
		name[0,i]
	end

	def categories_for_page(page)
		(page.ymf_data['categories'] || page.ymf_data['category']).to_a
	end

	def url_for_page(page)
		# if the file defines a permalink, use it
		url = page.ymf_data['permalink']
		return url unless url.nil?
		# does the file belong to a collection?
		collection_name = collection_name_for_page page
		if collection_name.nil? then
			# if not, just use the file path
			path = page.path
			if Formats.has_key? File.extname path then
				'/' + path.gsub(/\..+$/, '.html')
			else
				'/' + path
			end
		else
			# if so, use the permalink config option
			template = @config['permalink'] # TODO: collection-specific settings
			date = date_for_page page
			('/' + template).gsub(/:(i_)?[a-z]+/) do |tag|
				case tag
				when ':categories'
					(categories_for_page page).join('/')
				when ':day'
					date.strftime('%d')
				when ':i_day'
					date.strftime('%e')
				when ':i_month'
					date.strftime('%m').to_i
				when ':month'
					date.strftime('%m')
				when ':title'
					slug_for_page page
				when ':year'
					date.strftime('%Y')
				else
					raise "Unknown permalink tag '#{tag}'"
				end
			end.gsub(%r{//+}, '/') # collapse double slashes
		end
	end

	def collection_name_for_page(page)
		if m = %r{^_([^/]+)/}.match(page.path) then
			m[1]
		else
			nil
		end
	end

	def render_all
		dst_root = @config['destination']
		@index.each do |item|
			dst_path = File.join(dst_root, item.url)
			# If you are planning to use RewriteRule or MultiViews to hide file
			# extensions in the URL, you will still want them on the file.
			if (File.extname dst_path) == '' then
				dst_path << '.html'
			end
			if item.needs_render? dst_path then
				dst_parent = File.dirname dst_path
				FileUtils.mkdir_p dst_parent unless File.exists? dst_parent
				item.render_to dst_path
			end
		end
	end

	# Handle Liquid Template access dynamically
	# documented: time, posts, related_posts, categories.CATEGORY, tags.TAG

	def to_liquid
		self
	end

	def has_key?(key)
		builtins = [
			'pages',         # array of all pages
			'posts',         # array of all posts, in reverse chrono order
			'related_posts', # an array of posts related to the current post
			'time',          # time the site was built
			'categories',    # a hash of category name => array of posts
			'tags'           # a hash of tag name => array of posts
		]
		(builtins.include? key) || (@config.has_key? key)
	end

	def [](key)
		case key
		when 'pages'
			@index.all_pages
		when 'posts'
			@index.all_posts
		when 'related_posts'
			puts 'WARNING: site.related_posts not yet implemented'
			[]
		when 'time'
			@time
		when 'categories'
			@index.all_posts_by_category
		when 'tags'
			@index.all_posts_by_tag
		else
			@config[key]
		end
	end
	
end

end # module
