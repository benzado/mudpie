require 'mudpie/item'
require 'mudpie/config'

module MudPie
	
	FILTERS = {}
	
	DEFAULTS_FILENAME_PATTERN = %r{^defaults\.?(.+)\.yml$};
	
	class Compiler
	
		def initialize(site_root)
			@CONFIG = Config.new(site_root)
			@DEFAULTS = {}
			@SOURCE_PATHS = [] # files to be compiled
			@RESOURCE_PATHS = [] # files to be copied
			@LAYOUT_TEMPLATES = {}
			load_plugins
			scan_content_dir get_path('content_root')
		end
		
		def base_url
			@CONFIG['base_url']
		end
		
		def get_path(name, subpath = nil)
			@CONFIG.get_path(name, subpath)
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
			# if there were any fixed system defaults, they would go here
			metadata = {}
			# add defaults for each directory, top to bottom (so bottom takes
			# precedence)
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
				# skip self and parent directories
				next if (name == '.' or name == '..')
				# skip ignored files, like .DS_Store
				next if (@CONFIG['ignore_filenames'].include? name)
				path = dir_path.append_path_component(name)
				if (File.directory?(root + path)) then
					scan_content_dir root, path
				elsif (m = DEFAULTS_FILENAME_PATTERN.match(name)) then
					# if it is a defaults.*.yml file, load it
					@DEFAULTS[m[1] + dir_path] = YAML.parse_file(root + path).transform
				elsif (path.end_with? '.mp') then
					@SOURCE_PATHS.push path[0, path.length - 3]
				else
					@RESOURCE_PATHS.push path
				end
			end
		end
		
		def rescan_content_dir
			@DEFAULTS = {}
			@SOURCE_PATHS = []
			@RESOURCE_PATHS = []
			scan_content_dir get_path('content_root')
		end
		
		def items_for_path(pattern)
			@SOURCE_PATHS.select { |p| pattern.match(p) }.map { |p| Item.new(p, self) }
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
		
		def update_all
			@SOURCE_PATHS.each { |p| compile_path p }
			@RESOURCE_PATHS.each { |p| copy_path p }
		end
	
	end

end

Dir.glob(File.dirname(__FILE__) + '/plugins/*.rb').each do |name|
	puts "Loading built-in plugin #{name}"
	load name
end
