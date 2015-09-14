require 'pathname'
require 'mudpie/command'

module MudPie::Command
  class Prep < BasicCommand
    def initialize_option_parser(opts)
      opts.banner = 'Prep a workspace'
    end

    def execute
      if path_args.empty?
        path_args << Dir.pwd
      end
      path_args.each do |arg|
        root = Pathname.new(arg)
        create_directory(root + '.mudpie')
        create_directory(root + 'source')
        create_directory(root + 'layout')
        create_file(root + 'pie.yml')
      end
    end

    def create_directory(dir)
      logger.info "Creating directory #{dir}"
      dir.mkpath
    rescue => e
      logger.warn e.message
    end

    def create_file(file)
      if file.exist?
        logger.info "#{file.basename} already exists at #{file}"
      else
        logger.info "Creating file #{file}"
        template = template_named file.basename
        logger.debug "Template Path: #{template}"
        file.open('w') do |f|
          f.write template.read
        end
      end
    end

    def template_named(name)
      path = "mudpie/templates/#{name}"
      $:.map { |prefix| Pathname.new(prefix) + path }.find(&:exist?)
    end
  end
end
