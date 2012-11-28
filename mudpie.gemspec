Gem::Specification.new do |s|
  s.name = "mudpie"
  s.version = "2.0"
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
end
