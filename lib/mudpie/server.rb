require 'webrick'
require 'xmlrpc/server'

module MudPie

	class Server < WEBrick::HTTPServer
	
		def initialize(site_root, compile_on_demand = true)
			@SITE_ROOT = File.expand_path(site_root)
			super(:Port => 3000)
			@compiler = Compiler.new(@SITE_ROOT)
			@compiler.load_config
			if compile_on_demand then
				mount "/", LiveServlet
#				mount_metaweblog
			else
				output_root = @compiler.get_path('output_root')
				mount "/", WEBrick::HTTPServlet::FileHandler, output_root
			end
			['INT', 'TERM', 'HUP'].each do |name|
				trap(name) { shutdown }
			end
		end

		def mount_metaweblog
			xmlrpc = XMLRPC::WEBrickServlet.new
			xmlrpc.add_handler("metaWeblog", MetaWeblog.new(self))
			xmlrpc.set_default_handler do |name, *args|
				puts "Call to missing method #{name}(#{args.inspect})"
				raise XMLRPC::FaultException.new(-99, "Method #{name} missing or wrong number of arguments.")
			end			
			mount "/xmlrpc.php", xmlrpc
		end
		
		def compiler
			@compiler
		end
		
	end

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
				if @compiler.should_compile path then
					item = Item.new(path, @compiler)
					res.body = item.compiled_output
				else
					super(req, res)
				end
			else
				raise WEBrick::HTTPStatus::NotFound
			end
		end
	
	end

	
	# http://www.xmlrpc.com/metaWeblogApi
	
	class MetaWeblog

		def initialize(server)
			@compiler = server.compiler
		end

		def newPost(blogId, user, password, data, publish = true)
			postId = Time.now.to_i.to_s
			path = @compiler.get_path('content_root', postId + '.html')
			data['title']
			data['link']
			data['description']
			# return postId as string
			return path
		end

		def editPost(postId, user, password, data, publish)
			# return true/false
			true
		end

		def getPost(postId, user, password, extra = {})
			# return struct
			{}
		end

		def getRecentPosts(blogId, user, password, limit)
			items = @compiler.blog_items(limit)
			return items.map do |item|
				
			end
		end

		def getCategories(blogId, user, password)
			return []
		end

		def newMediaObject(blogId, user, password, data)
			{ :url => "/" }
		end

	end
	
end
