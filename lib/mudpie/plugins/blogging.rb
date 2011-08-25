module MudPie

	# Functions added to Item are accessible from all pages

	class Item
		def blog_items(limit = false)
			@compiler.blog_items(limit)
		end
	end

	# Blog items are special: the URL is dependent on the time, post-id, etc.
	# TODO: make URL configurable

	class BlogItem < Item
		def initialize(path, compiler)
			super(path, compiler)
			@source_path = compiler.get_path('posts_root', path)
			if m = %r{/([^./]+)\.mp$}.match(path) then
				@slug = m[1]
			end
		end
		def source_path
			@source_path
		end
		def load_content
			content = super
			if @datetime.nil? then
				if File.exist? source_path then
					@datetime = File.mtime source_path
				else
					@datetime = Time.now
				end
			end
			@path = @datetime.strftime("/blog/%Y/%m/#{@slug}.html")
			return content
		end
	end

	class Compiler
	
		def load_blog_items_from_path(root, dir_path = '/')
			Dir.foreach(root + dir_path) do |name|
				next if (name == '.' or name == '..')
				path = dir_path.append_path_component(name)
				if (File.directory?(root + path)) then
					load_blog_items_from_path root, path
				elsif name.end_with? '.mp' then
					@POST_SOURCE_PATHS.push path
				end
			end
		end
	
		def load_blog_items
			@POST_SOURCE_PATHS = []
			load_blog_items_from_path get_path('posts_root')
			@blog_items = @POST_SOURCE_PATHS.map { |p| BlogItem.new(p, self) }
			@blog_items.each {|item| item.load_content }
			@blog_items.sort! {|a,b| b.datetime <=> a.datetime }
			# id map for metaweblog support
			@blog_paths_by_id = {}
			@blog_items.each do |item|
				@blog_paths_by_id[item.postid] = item.path
			end
		end
		
		def flush_blog_items
			@blog_items = nil
			@blog_paths_by_id = nil
		end

		def blog_items(limit = false)
			load_blog_items if @blog_items.nil?
			if limit then
				@blog_items.take(limit)
			else
				@blog_items
			end
		end

		def blog_path_for_id(postid)
			load_blog_items if @blog_paths_by_id.nil?
			@blog_paths_by_id[postid] || postid
		end
		
		def blog_item_for_id(postid)
			Item.new((blog_path_for_id postid), self)
		end
		
	end
	
end
