module MudPie

class PageSet

	def initialize(index, key, value)
		@index = index
		@key = key
		@value = value
	end

	def pages
		@pages || (@pages = @index.all_for_key_and_value @key, @value)
	end

	def count
		pages.length
	end

	def to_liquid
		puts "PageSet<#{@key},#{@value}> building set" if @pages.nil?
		pages
	end

	def has_key?(key)
		puts "PageSet<#{@key},#{@value}> test for #{key}"
		key == 'size'
	end

	def [](key)
		case key
		when 'size'
			count
		else
			pages[key]
		end
	end

end

end # module
