require 'rake/mudpietask'

Rake::MudPieTask.new

module Rake::MudPie
  FILES = {
    '.gitignore' => 'tmpl/gitignore',
    'site.rb' => 'tmpl/site.rb'
  }
  DIRS = %w[ layouts pages parts ]
end

Rake::MudPie::FILES.each do |name, tmpl|
  file name do |t|
    cp File.join(MudPie::GEM_ROOT, tmpl), t.name
  end
end

Rake::MudPie::DIRS.each do |name|
  file name do |t|
    mkdir t.name
  end
end

desc "Set up a new MudPie site"
task :init => Rake::MudPie::FILES.keys.concat(Rake::MudPie::DIRS)
