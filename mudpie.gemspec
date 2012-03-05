Gem::Specification.new do |s|
  s.name = "mudpie"
  s.version = "1.0"
  s.platform = Gem::Platform::RUBY
  s.authors = ["Benjamin Ragheb"]
  s.email = ["ben@benzado.com"]
  s.homepage = "http://github.com/benzado/mudpie"
  s.summary = "Mud Pie"
  s.description = "Dirt simple baked websites"
  s.rubyforge_project = s.name

  s.required_rubygems_version = ">= 1.3.6"

  files = `git ls-files`.split("\n")
  s.files = files
  s.executables = files.map {|f| f =~ /^bin\/(.*)/ ? $1 : nil }.compact

  s.require_path = 'lib'
end
