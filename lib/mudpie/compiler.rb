require 'mudpie/item'

module MudPie
	
	FILTERS = {}
	
	DEFAULTS_FILENAME_PATTERN = %r{^defaults\.?(.*)\.yml$};
	
	class Compiler
	
		def initialize(site_root)
			@SITE_ROOT = File.expand_path(site_root)
			@DEFAULTS = {}
			@CONTENT_PATHS = []
			@LAYOUT_TEMPLATES = {}
			load_config
			load_plugins
			scan_content_dir get_path('content_root')
		end
		
		def load_config
			@CONFIG = {
				'plugin_path' => 'plugins',
				'content_root' => 'content',
				'layouts_root' => 'layouts',
				'output_root' => 'output',
				'base_url' => 'http://localhost:3000',
				'compile_extensions' => ['css', 'htm', 'html', 'xml'],
				'ignore_filenames' => ['.DS_Store']
			}
			config_path = @SITE_ROOT.append_path_component('config.yml')
			if File.exist? config_path then
				puts "Loading configuration #{config_path}"
				@CONFIG.merge!(YAML.parse_file(config_path).transform)
			end
		end
		
		def base_url
			@CONFIG['base_url']
		end
		
		def get_path(name, subpath = nil)
			p = @CONFIG[name]
			if p[0] != '/' then
				p = @SITE_ROOT.append_path_component(p)
			end
			if subpath then
				p.append_path_component(subpath)
			else
				p
			end
		end

		def template_for_layout(layout)
			template = @LAYOUT_TEMPLATES[layout]
			if (template.nil?) then
				layout_path = get_path('layouts_root', layout)
				template = ERB.new(File.new(layout_path), nil, "%<>")
				template.filename = layout_path
				@LAYOUT_TEMPLATES[layout] = template
			end
			template
		end
		
		def defaults_for_path(path)
			# baked in system defaults
			metadata = {}
			# add for each directory
			extension = path.path_extension
			i = path.index('/')
			while not i.nil? do
				prefix = if i == 0 then '/' else path[0, i] end
				[prefix, extension + prefix].each do |p|
					d = @DEFAULTS[p]
					metadata.merge!(d) unless d.nil?
				end
				i = path.index('/', i + 1)
			end
			return metadata
		end
		
		def load_plugins
			Dir.glob(get_path('plugin_path', '*.rb')) do |name|
				puts "Loading plugin #{name}"
				load name
			end
		end
		
		def scan_content_dir(root, dir_path = '/')
			Dir.foreach(root + dir_path) do |name|
				next if (name == '.' or name == '..')
				next if (@CONFIG['ignore_filenames'].include? name)
				path = dir_path.append_path_component(name)
				if (File.directory?(root + path)) then
					scan_content_dir root, path
				elsif (m = DEFAULTS_FILENAME_PATTERN.match(name)) then
					@DEFAULTS[m[1] + dir_path] = YAML.parse_file(root + path).transform
				else
					@CONTENT_PATHS.push path
				end
			end
		end
		
		def rescan_content_dir
			@DEFAULTS = {}
			@CONTENT_PATHS = []
			scan_content_dir get_path('content_root')
		end
		
		def items_for_path(pattern)
			@CONTENT_PATHS.select { |p| pattern.match(p) }.map { |p| Item.new(p, self) }
		end

		def compile_path(path)
			puts "Compiling #{path}"
			item = Item.new(path, self)
			FileUtils.mkpath(File.dirname(item.output_path))
			begin
				output = item.compiled_output
				File.open(item.output_path, 'w') { |f| f.write(output) }
			rescue StandardError => e
				puts "\tERROR: " + e.message
				puts "\t" + e.backtrace.join("\n\t")
				# TODO: filter backtrace to include only content and layouts
			end
		end
		
		def copy_path(path)
			content_path = get_path('content_root', path)
			output_path = get_path('output_root', path)
			if File.exist? output_path then
				return if ((File.mtime content_path) <= (File.mtime output_path))
				FileUtils.rm output_path
			else
				FileUtils.mkpath(File.dirname(output_path))
			end
			puts "Copying #{path}"
			FileUtils.cp content_path, output_path
		end
		
		def should_compile(path)
			@CONFIG['compile_extensions'].include? path.path_extension
		end
		
		def update_path(path)
			if should_compile path then
				compile_path path
			else
				copy_path path
			end
		end
		
		def update_all
			@CONTENT_PATHS.each { |path| update_path path }
		end
	
	end

end

Dir.glob(File.dirname(__FILE__) + '/plugins/*.rb').each do |name|
	puts "Loading built-in plugin #{name}"
	load name
end
