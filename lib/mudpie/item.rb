module MudPie	

	class Item

		include ERB::Util
		
		SYSTEM_SYMBOLS = [ :compiler, :path, :url ]

		def initialize(path, compiler)
			@path = path
			@compiler = compiler
			@url = @compiler.base_url + path
			if File.exist? content_path then
				@datetime = File.mtime content_path
			else
				@datetime = Time.now
			end
		end
		
		def [](symbol)
			begin
				isymbol = "@#{symbol}".to_sym
				self.instance_variable_get isymbol
			rescue NameError
				nil
			end
		end

		def []=(symbol, value)
			raise StandardError if SYSTEM_SYMBOLS.find_index(symbol)
			isymbol = "@#{symbol}".to_sym
			self.instance_variable_set(isymbol, value)
		end

		def method_missing(symbol, *args, &block)
			self[symbol]
		end
		
		def properties
			self.instance_variables.map do |isymbol|
				istr = isymbol.to_s
				istr[1,istr.length-1].to_sym
			end - SYSTEM_SYMBOLS
		end

		def content_path
			@compiler.get_path('content_root', @path)
		end

		def output_path
			@compiler.get_path('output_root', @path)
		end
		
		def load_defaults
			@compiler.defaults_for_path(@path).each_pair do |k,v|
				self[k] = v
			end
		end

		def load_content
			t = ERB.new(File.new(self.content_path), nil, "%<>")
			t.filename = self.content_path
			t.result binding
		end

		def apply_filters(content)
			@filters.kind_of?(Array) && @filters.each do |name|
				f = MudPie::FILTERS[name]
				if f.nil? then
					print "Unknown filter: " + name + "\n"
				else
					content = f.call(self, content)
				end
			end
			return content
		end

		def default_layout
			layout_name = '_.' + @path.path_extension
			default_layout_path = @compiler.get_path('layouts_root', layout_name)
			if File.exist? default_layout_path then
				layout_name
			else
				nil
			end
		end

		def apply_layout(b)
			template = @compiler.template_for_layout @layout
			output = template.result b
			@layout = @embed_in_layout
			@embed_in_layout = nil
			return output
		end

		def compiled_output
			b = binding
			self.load_defaults
			content = self.load_content
			content = self.apply_filters content
			if @layout.nil? then
				@layout = default_layout
			end
			while (not @layout.nil?) do
				content = self.apply_layout b
			end
			return content
		end

		def compiled_output_for_layout(layout)
			b = binding
			self.load_defaults
			content = self.load_content
			content = self.apply_filters content
			template = @compiler.template_for_layout layout
			template.result b
		end

	end

end
