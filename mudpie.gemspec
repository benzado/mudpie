# http://guides.rubygems.org/specification-reference/

Gem::Specification.new do |s|
  s.name = "mudpie"
  s.version = "2.0.1"
  s.platform = Gem::Platform::RUBY
  s.authors = ["Benjamin Ragheb"]
  s.email = ["ben@benzado.com"]
  s.homepage = "https://github.com/benzado/mudpie"
  s.summary = "Mud Pie"
  s.description = "Baked websites, dirt simple."
  s.rubyforge_project = s.name
  s.required_rubygems_version = ">= 1.3.6"
  s.files = `git ls-files`.split("\n")
  s.require_path = 'lib'
  s.add_runtime_dependency 'rake', '~> 0.9.2'
  s.add_runtime_dependency 'sqlite3', '~> 1.3.6'
  s.add_runtime_dependency 'redcarpet', '~> 2.0.1'
end
