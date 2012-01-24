module MudPie

class Page < SourceFile

	def initialize(site, entry)
		@site = site
		@entry = entry
		super(entry.path, entry.ymf_len)
	end

	def url
		@entry.url
	end

	def format_proc
		name = ymf_data['filter']
		if name && !Formats.has_key?('.' + name) then
			puts "WARNING: filter `#{name}` not found"
		end
		Formats[name || (File.extname @path)]
	end

	def needs_render?(dst_path)
		if File.exists? dst_path then
			(File.mtime @path) > (File.mtime dst_path)
		else
			true
		end
	end

	def rendered_content(embed_in_layout = true)
		if ymf_len == 0 then
			File.read @path
		else
			context = { 'site' => @site, 'page' => self }
			# Step 1: run it through liquid
			content = Layout.render(@site, raw_content, context)
			# Step 2: filter if necessary
			content = format_proc.call self, content
			# Step 3: render layout (optional)
			layout_name = ymf_data['layout']
			if embed_in_layout && layout_name && layout_name != 'nil' then
				layout = @site.layout layout_name
				layout.render content, context
			else
				content
			end
		end
	end

	def render_to(dst_path)
		if ymf_len == 0 then
			# File has no YMF, so just do a straight copy.
			puts "Copying #{dst_path}"
			begin
				FileUtils.cp @path, dst_path
			rescue => e
				puts "ERROR: #{e}"
			end
		else
			puts "Rendering #{dst_path}"
			content = rendered_content
			File.open(dst_path, 'w') do |f|
				f.write content
			end
		end
	end

	# Liquid Template access
	# for pages: url, content
	# for posts: title, url, date, id, categories, tags, content

	def generated_title
		filename = File.basename @path
		if m = /^(\d+-\d+-\d+-)?([^.]+)/.match(filename) then
			title = m[2]
		else
			title = filename[0,(filename.index '.')]
		end
		title.gsub!(/-+/, ' ').gsub!(/^\S|\s\S/) {|x| x.upcase }
	end

	def to_liquid
		self
	end

	def has_key?(key)
		true
	end
	
	def [](key)
		case key
		when 'content'
			rendered_content false
		when 'date'
			Time.at @entry.date
		when 'id'
			ymf_data['id'] || @entry.url
		when 'title'
			ymf_data['title'] || generated_title
		when 'url'
			@entry.url
		else
			ymf_data[key]
		end
	end

end

end # module