module MudPie

	class Config
	
		def initialize(site_root)
			@SITE_ROOT = File.expand_path(site_root)
			# built-in system defaults
			@STORE = {
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
				@STORE.merge!(YAML.parse_file(config_path).transform)
			end
		end
		
		def get_path(name, subpath = nil)
			p = @STORE[name]
			if p[0] != '/' then
				p = @SITE_ROOT.append_path_component(p)
			end
			if subpath then
				p.append_path_component(subpath)
			else
				p
			end
		end
		
		def [](key)
			if @STORE.has_key?(key) then
				@STORE[key]
			else
				throw "no configuration option `#{key}`"
			end
		end
		
	end

end