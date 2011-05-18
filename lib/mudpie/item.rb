module MudPie	

	class Item

		include ERB::Util

		def initialize(path, compiler)
			@path = path
			@compiler = compiler
			@url = @compiler.base_url + path
			@filters = []
			layout_name = 'default.' + path.path_extension
			default_layout_path = @compiler.get_path('layout_root', layout_name)
			if File.exist? default_layout_path then
				@layout = layout_name
			end
			load_hash @compiler.defaults_for_path @path
		end

		def method_missing(symbol, *args, &block)
			eval('@' + symbol.id2name)
		end

		def content_path
			@compiler.get_path('content_root', @path)
		end

		def output_path
			@compiler.get_path('output_root', @path)
		end

		def load_hash(h)
			h.each_pair do |k,v|
				data = Marshal.dump(v)
				eval("@#{k} = Marshal.load('#{data}')")
			end
		end

		def load_content
			t = ERB.new(File.new(self.content_path), nil, "%<>")
			t.filename = self.content_path
			t.result binding
		end

		def apply_filters(content)
			@filters.each do |name|
				f = MudPie::FILTERS[name]
				if f.nil? then
					print "Unknown filter: " + name + "\n"
				else
					content = f.call(self, content)
				end
			end
			return content
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
			content = self.load_content
			content = self.apply_filters content
			while (not @layout.nil?) do
				content = self.apply_layout b
			end
			return content
		end

		def compiled_output_for_layout(layout)
			b = binding
			content = self.load_content
			content = self.apply_filters content
			template = @compiler.template_for_layout layout
			template.result b
		end

	end

end
