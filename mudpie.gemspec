# http://guides.rubygems.org/specification-reference/

$:.push File.expand_path("../lib", __FILE__)
require "mudpie/version"

Gem::Specification.new do |s|
  s.name        = 'mudpie'
  s.version     = MudPie::VERSION
  s.summary     = "Dirt-simple baked websites."
  s.description = <<EOD
MudPie is a tool for building static, or "baked", web sites from various source
files, such as Markdown or CoffeeScript. It is similar to tools like Jekyll or
nanoc, but designed a little bit differently.
- MudPie uses Rake and SQLite to speed up page generation.
- MudPie uses Sprockets asset pipeline (like Rails does) for stylesheet and
  Javascript compilation.
- MudPie does not require the use of Liquid templates, which were designed for
  allow untrusted people limited abilities; MudPie assumes you are building
  pages on your own computer and lets you use Turing complete languages.
EOD

  s.license     = 'BSD'

  s.author      = "Benjamin Ragheb"
  s.email       = 'ben@benzado.com'
  s.homepage    = MudPie::HOMEPAGE

  s.files       = `git ls-files`.split("\n")

  s.platform = Gem::Platform::RUBY
  s.required_ruby_version = '>= 1.9.3'
  s.add_runtime_dependency 'aws-sdk'
  s.add_runtime_dependency 'builder', '~> 3.2'
  s.add_runtime_dependency 'json', '~> 1.7.7'
  s.add_runtime_dependency 'nokogiri'
  s.add_runtime_dependency 'rake', '~> 10.0'
  s.add_runtime_dependency 'redcarpet', '~> 2.2'
  s.add_runtime_dependency 'sprockets', '~> 2.9'
  s.add_runtime_dependency 'sqlite3', '~> 1.3'

  s.executables = ['mudpie']
end
