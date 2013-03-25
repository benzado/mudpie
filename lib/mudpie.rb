require 'set'
require 'stringio'
require 'builder'
require 'rake/clean'

module MudPie
  VERSION = '2.0'
  GEM_ROOT = File.expand_path('..', File.dirname(__FILE__))
end

require 'mudpie/compressor'
require 'mudpie/page_context'
require 'mudpie/page'
require 'mudpie/layout'
require 'mudpie/bakery'
require 'mudpie/pantry'
require 'mudpie/page_query'
require 'mudpie/server'

require 'mudpie/renderer'
require 'mudpie/renderer/erb_renderer'
require 'mudpie/renderer/markdown_renderer'
require 'mudpie/renderer/ruby_renderer'

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

  compressor = MudPie::Compressor.new(bakery.target_files)
  compressor.compressed_files.each do |gzpath|
    path = compressor.uncompressed_path(gzpath)
    file gzpath => path do |t|
      compressor.compress path, gzpath
    end
  end

  task :pantry do
    bakery.pantry
  end

  task :bake => bakery.target_files

  task :compress => compressor.compressed_files

  namespace :serve do

    task :cold do
      MudPie::Server.new(bakery).start
    end

    task :hot do
      bakery.serve_hot!
      MudPie::Server.new(bakery).start
    end

  end

  task :init => %w[.gitignore layouts pages parts site.rb]

  %w[layouts pages parts].each do |dir|
    file(dir) { |t| mkdir(t.name) }
  end

  file '.gitignore' do |t|
    cp File.join(MudPie::GEM_ROOT, 'tmpl/gitignore'), t.name
  end

  file 'site.rb' do |t|
    cp File.join(MudPie::GEM_ROOT, 'tmpl/site.rb'), t.name
  end

end

desc "Set up a new site"
task :init => 'mp:init'

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
