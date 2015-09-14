# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'mudpie/version'

Gem::Specification.new do |spec|
  spec.name          = 'mudpie'
  spec.version       = MudPie::VERSION
  spec.authors       = ['Benjamin Ragheb']
  spec.email         = ['ben@benzado.com']
  spec.summary       = %q{TO-DO: Write a short summary. Required.}
  spec.description   = %q{TO-DO: Write a longer description. Optional.}
  spec.homepage      = ''
  spec.license       = 'GPL'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^test/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.10'
  spec.add_development_dependency 'rake', '~> 10.4'

  spec.add_dependency 'kramdown', '~> 1.8'
  spec.add_dependency 'sqlite3', '~> 1.3'
  spec.add_dependency 'term-ansicolor', '~> 1.3'
end
