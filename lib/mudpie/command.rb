require 'mudpie/compiler'
require 'mudpie/server'
require 'mudpie/config'

module MudPie

HELP_TEXT = <<END_HELP_TEXT
MudPie v#{VERSION}

usage: mp <command> [<args>]

commands:
    bake    Compiles site content into the output directory.
    serve   Starts a web server for testing the site.
    deploy	Deploys site to production server.
    help    Prints this help text.

END_HELP_TEXT

class Command

	def initialize(argv)
		@command = argv.shift || 'help'
		@argv = argv
	end
	
	def run
		m = begin
			s = "do_" + @command
			self.method(s.to_sym)
		rescue NameError
			puts "No such command '#{@command}'."
		end
		m.call unless m.nil?
	end

	def do_help
		puts HELP_TEXT
	end

	def do_bake
		path = @argv.shift || '.'
		puts "Baking site at #{path}"
		c = Compiler.new(path)
		c.update_all
	end

	def do_serve
		path = @argv.shift || '.'
		puts "Serving site at #{path}"
		s = Server.new(path)
		s.start
	end
	
	# Ideally, we should bake to a temporary directory and then deploy.

	def do_deploy
		path = @argv.shift || '.'
		puts "Deploying site at #{path}"
		config = Config.new(path)
		rsync_opts = %w{
			--verbose --human-readable --progress
			--checksum --compress
			--recursive
			--update
			--times --omit-dir-times
		}.join(' ')
		output_path = config.get_path('output_root')
		deploy_root = config['deploy_root']
		upload_command = "rsync #{rsync_opts} #{output_path}/ #{deploy_root}/"
		puts "Executing `#{upload_command}`"
		system upload_command
	end

end

end