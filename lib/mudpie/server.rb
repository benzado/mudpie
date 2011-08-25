require 'webrick'
require 'mudpie/metaweblog'

module MudPie

	class Server < WEBrick::HTTPServer
	
		def initialize(site_root, compile_on_demand = true)
			@SITE_ROOT = File.expand_path(site_root)
			super(:Port => 3000)
			@compiler = Compiler.new(@SITE_ROOT)
			if compile_on_demand then
				mount "/", LiveServlet
				BlogStore.new(self)
			else
				output_root = @compiler.get_path('output_root')
				mount "/", WEBrick::HTTPServlet::FileHandler, output_root
			end
			['INT', 'TERM', 'HUP'].each do |name|
				trap(name) { shutdown }
			end
		end
		
		def compiler
			@compiler
		end
		
	end

	# TODO: add plug-in hook, so that blog entries can be rendered here

	class LiveServlet < WEBrick::HTTPServlet::FileHandler
	
		def initialize(server)
			@compiler = server.compiler
			super(server, @compiler.get_path('output_root'))
		end
	
		def do_GET(req, res)
			path = req.path
			if path[-1,1] == '/' then
				path << 'index.html'
			end
			content_path = @compiler.get_path('content_root', path)
			if File.exists? content_path then
				super(req, res)
			elsif File.exists? content_path + '.mp' then
				item = Item.new(path, @compiler)
				res.body = item.compiled_output
			else
				raise WEBrick::HTTPStatus::NotFound
			end
		end
	
	end

end
