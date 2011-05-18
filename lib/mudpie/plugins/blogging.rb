module MudPie

	class Compiler
		def blog_items(limit = false)
			items = items_for_path(Regexp.new(@CONFIG['blog_item_pattern']))
			items.each {|item| item.load_content }
			items.sort! {|a,b| b.datetime <=> a.datetime }
			if limit then
				items.take(limit)
			else
				items
			end
		end
	end

	class Item
		def blog_items(limit = false)
			@compiler.blog_items(limit)
		end
	end
	
end
