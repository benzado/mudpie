module MudPie

	class Compiler
	
		def load_blog_items
			@blog_items = items_for_path(Regexp.new(@CONFIG['blog_item_pattern']))
			@blog_items.each {|item| item.load_content }
			@blog_items.sort! {|a,b| b.datetime <=> a.datetime }
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

	class Item
		def blog_items(limit = false)
			@compiler.blog_items(limit)
		end
	end
	
end
