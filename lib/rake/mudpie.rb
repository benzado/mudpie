require 'rake/clean'
require 'rake/sprocketstask'
require 'mudpie'
require 'rack'
require 'rack/mudpie'

namespace :mp do

  CLEAN.include(MudPie::Bakery::OUTPUT_ROOT)
  CLOBBER.include(MudPie::Pantry::DB_PATH)

  bakery = begin
    pages = Rake::FileList['pages/**/*']
    pages.include('pages/**/.htaccess')
    MudPie::Bakery.new(pages)
  end

  bakery.dependencies.each do |target, sources|
    file target => sources do
      bakery.bake target
    end
  end

  Rake::SprocketsTask.new do |t|
    t.environment = bakery.sprockets_environment
    t.output      = File.join(MudPie::Bakery::OUTPUT_ROOT, 'assets')
    t.assets      = bakery.sprockets_assets
  end

  task :bake => [:assets] + bakery.target_files

  output_files = Rake::FileList[MudPie::Bakery::OUTPUT_ROOT + '/**/*']
  compressor = MudPie::Compressor.new(output_files)
  compressor.compressed_files.each do |gzpath|
    path = compressor.uncompressed_path(gzpath)
    file gzpath => path do |t|
      compressor.compress path, gzpath
    end
  end

  task :compress => compressor.compressed_files

  namespace :serve do

    %w[INT TERM HUP].each do |signal|
      trap(signal) { Rack::Handler::WEBrick.shutdown }
    end

    task :cold do
      Rack::Handler.default.run Rack::MudPie::cold_app(bakery)
    end

    task :hot do
      Rack::Handler.default.run Rack::MudPie::hot_app(bakery)
    end

  end

  file('.gitignore') { |t| cp File.join(MudPie::GEM_ROOT, 'tmpl/gitignore'), t.name }
  file('site.rb')  { |t| cp File.join(MudPie::GEM_ROOT, 'tmpl/site.rb'), t.name }

  %w[ layouts pages parts ].each do |dir|
    file(dir) { |t| mkdir(t.name) }
  end

  desc "Set up a new MudPie site"
  task :init => %w[.gitignore layouts pages parts site.rb]

end

desc "Render pages to `#{MudPie::Bakery::OUTPUT_ROOT}`"
task :bake => 'mp:bake'

desc "Compress files in `#{MudPie::Bakery::OUTPUT_ROOT}`"
task :compress => 'mp:compress'

namespace :serve do

  desc "Start static HTTP server in `#{MudPie::Bakery::OUTPUT_ROOT}`"
  task :cold => 'mp:serve:cold'

  desc "Start dynamic HTTP server for live previews."
  task :hot => 'mp:serve:hot'

end
