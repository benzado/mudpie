require 'xmlrpc/server'
require 'date'
require 'base64'

module MudPie
	
	# http://www.xmlrpc.com/metaWeblogApi
	# http://infinite-sushi.com/2005/12/programmatic-interfaces-the-movabletype-xmlrpc-api/
	
	# THINK: maybe postid should equal path? (don't want path to change)
	# TODO: figure out right way to handle pubDate
	# TODO: figure out right way to handle slug
	# THINK: maybe wordpress API is a better fit?
	
	class BlogStore

		def initialize(server)
			@compiler = server.compiler
			xmlrpc = XMLRPC::WEBrickServlet.new
			xmlrpc.add_handler("blogger", Blogger.new(self))
			xmlrpc.add_handler("metaWeblog", MetaWeblog.new(self))
			xmlrpc.add_handler("mt", MT.new(self))
			xmlrpc.add_handler("wp", WP.new(self))		
			xmlrpc.set_default_handler do |name, *args|
				puts "Call to missing method #{name}(#{args.inspect})"
				raise XMLRPC::FaultException.new(-99, "Method #{name} missing or wrong number of arguments.")
			end			
			server.mount "/xmlrpc.php", xmlrpc
		end
				
		def slug_from_title(title)
			title.downcase.gsub(/[^0-9a-z]/, ' ').slice(0,20).gsub(/ +/, '-')
		end
		
		def item_for_id(postid)
			@compiler.blog_item_for_id(postid)
		end
		
		def recent_items(limit)
			@compiler.blog_items(limit)
		end
		
		def write_item(item, body)
			fullpath = item.source_path
			FileUtils.mkpath(File.dirname(fullpath))
			File.open(fullpath, 'w') do |f|
				item.properties.each do |k|
					v = item[k]
					if v.kind_of? Time then
						quoval = "Time.at(#{v.to_i})"
					elsif (v.kind_of? Integer or v.kind_of? Float) then
						quoval = v.to_s
					else
						quoval = v.inspect
					end
					f.write "% @#{k} = #{quoval} # #{v.class}\n"
				end
				f.write body
			end
			@compiler.flush_blog_items
			@compiler.rescan_content_dir
			true
		end
		
		def new_post(body, meta = {})
			postid = body.object_id.to_s
			t = meta[:datetime] || Time.now
			s = slug_from_title(meta[:title] || 'post')
			path = sprintf('/blog/%04d/%02d/%02d/%s.html', t.year, t.month, t.mday, s)
			item = Item.new(path, @compiler)
			item[:postid] = postid
			item[:datetime] = t
			meta.each_pair { |k,v| item[k.to_sym] = v }
			write_item(item, body)
			postid
		end
		
		def delete_item_for_id(postid)
			item = item_for_id(postid)
			FileUtils.rm(item.source_path)
			@compiler.flush_blog_items
			@compiler.rescan_content_dir
			true
		end

		ISO8601 = '%Y-%m-%dT%H:%M:%S%z'
		
		def to_ISO8601(t)
			if t then
				t.strftime(ISO8601)
			end
		end
		
		def from_ISO8601(s)
			if s then
				dt = DateTime.strptime(ISO8601, s).new_offset
				Time.utc(dt.year, dt.month, dt.day, dt.hour, dt.min, dt.sec)
			end
		end
		
		def blog_url
			@compiler.base_url
		end
		
		def new_media(name, bits)
			path = '/media/'.append_path_component name
			content_path = @compiler.get_path('content_root', path)
			FileUtils.mkpath(File.dirname(content_path))
			File.open(content_path, 'w') { |f| f.write(bits) }
			@compiler.base_url + path
		end
		
	end

	class Blogger

		def initialize(store)
			@store = store
		end

		def newPost(appkey, blogid, username, password, content, publish)
			@store.new_post content
		end

		def editPost(appkey, postid, username, password, content, publish)
			item = @store.item_for_id(postid)
			item.load_content
			@store.write_item item, content
		end

		def deletePost(appkey, postid, username, password, publish)
			@store.delete_item_for_id(postid)
		end
		
		def getRecentPosts(appkey, blogid, username, password, limit)
			@store.recent_items(limit).map do |item|
				{
					:dateCreated => @store.to_ISO8601(item.datetime),
					:userid => "0",
					:postid => item.postid || item.path,
					:content => item.load_content
				}
			end
		end
		
		def getUsersBlogs(appkey, username, password)
			[{
				:url => @store.blog_url,
				:blogid => "0",
				:blogName => "MudPie"
			}]
		end
		
# 		def getUserInfo(appkey, username, password)
# 			{
# 				:userid => username,
# 				:firstname => "",
# 				:lastname => "",
# 				:nickname => "",
# 				:email => "",
# 				:url => ""
# 			}
# 		end

	end
	
	class MetaWeblog

		def initialize(store)
			@store = store
		end

		def newPost(blogid, username, password, data, publish)
			begin
				@store.new_post data['description'], {
					:title => data['title'],
					:datetime => @store.from_ISO8601(data['dateCreated']),
					:filters => [ data['mt_convert_breaks'] ].compact,
					:allow_comments => data['mt_allow_comments'] != 0,
					:excerpt => data['mt_excerpt'],
					:keywords => data['mt_keywords'],
					:more => data['mt_text_more']
				}
			rescue StandardError => e
				puts e
				puts e.backtrace
			end
		end

		def editPost(postid, username, password, data, publish)
			begin
				item = @store.item_for_id(postid)
				item.load_content
				item[:title] = data['title']
				t = @store.from_ISO8601(data['dateCreated'])
				item[:datetime] = t unless t.nil?
				@store.write_item item, data['description']
			rescue StandardError => e
				puts e
				puts e.backtrace.inspect
			end
		end
		
		def _struct_for_item(item)
			body = item.load_content
			{
				:dateCreated => @store.to_ISO8601(item.datetime),
				:postid => item.postid || item.path,
				:description => body,
				:title => item.title,
				:link => item.url,
				:permaLink => item.url,
				:mt_excerpt => item.excerpt,
				:mt_text_more => item.more,
				:mt_allow_comments => item.allow_comments,
				:mt_convert_breaks => item.filters && item.filters.first,
				:mt_keywords => item.keywords
			}.delete_if {|k,v| v.nil? }
		end

		def getPost(postid, username, password)
			_struct_for_item @store.item_for_id(postid)
		end

		def getRecentPosts(blogid, username, password, limit)
			@store.recent_items(limit).map do |item|
				_struct_for_item item
			end
		end

		def newMediaObject(blogid, username, password, data)
			bits = Base64.decode64(data['bits'])
			name = data['name']
			@store.new_media(name, bits)
		end

	end
	
	class MT

		# http://infinite-sushi.com/2005/12/programmatic-interfaces-the-movabletype-xmlrpc-api/

		def initialize(store)
			@store = store
		end

		def supportedMethods
			[:supportedTextFilters, :getRecentPostTitles]
		end
		
		def getRecentPostTitles(blogid, username, password, limit)
			@store.recent_items(limit).map do |item|
				{
					:dateCreated => @store.to_ISO8601(item.datetime),
					:userid => "0",
					:postid => item.postid,
					:title => item.title
				}.delete_if {|k,v| v.nil? }
			end
		end

# 		def getCategoryList(blogid, username, password)
# 			[{
# 				:categoryId => "",
# 				:categoryName => ""
# 			}]
# 		end
# 		
# 		def getPostCategories(postid, username, password)
# 			[{
# 				:categoryId => "",
# 				:categoryName => "",
# 				:isPrimary => false
# 			}]
# 		end
# 		
# 		def setPostCategories(postid, username, password, categories)
# 			true
# 		end
		
		def supportedTextFilters
			FILTERS.keys.map do |filter|
				{
					:key => filter,
					:label => filter
				}
			end
		end
		
	end

	class WP
		
		# http://codex.wordpress.org/XML-RPC_wp
		
		def initialize(store)
			@store = store
		end

	end
	
end
