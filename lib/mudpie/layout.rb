module MudPie

class Layout < SourceFile

	def self.opts(site)
		{ :filters => [MudPie::Filters], :registers => { :site => site } }
	end

	def self.render(site, content, context)
		begin
			Liquid::Template.parse(content).render!(context, (Layout.opts site))
		rescue => e
			puts "Liquid Exception: #{e.message} in #{@page}"
		end
	end

	def initialize(site, name)
		@site = site
		super(File.join(@site.config['layouts_root'], name + '.html'))
	end

	def template
		if @template.nil? then
			@template = Liquid::Template.parse self.raw_content
		end
		@template
	end

	def render(content, page_context)
		puts "  Embedding in #{@path}"
		context = ymf_data.merge page_context
		context['content'] = content
		begin
			output = self.template.render! context, (Layout.opts @site)
		rescue => e
			puts "Liquid Exception: #{e.message} in layout #{@path}"
		end
		parent_layout_name = ymf_data['layout']
		if parent_layout_name then
			parent_layout = @site.layout parent_layout_name
			parent_layout.render output, context
		else
			output
		end
	end

end

end # module
