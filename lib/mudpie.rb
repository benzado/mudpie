# rubygems
require 'rubygems'

# stdlib
require 'fileutils'
require 'yaml'
YAML::ENGINE.yamler = 'syck'

# dependencies
require 'liquid'
require 'sqlite3'

module MudPie
  VERSION = '2.0'
end

# equip the kitchen
require 'mudpie/command'
require 'mudpie/compressor'
require 'mudpie/config'
require 'mudpie/filters'
require 'mudpie/formats'
require 'mudpie/index'
require 'mudpie/index_entry'
require 'mudpie/page_set'
require 'mudpie/server'
require 'mudpie/site'
require 'mudpie/source_file'
  require 'mudpie/page'
  require 'mudpie/layout'

# plugins

# tags
glob = File.join(File.dirname(__FILE__), 'mudpie/tags/*.rb')
Dir[glob].each do |f|
  require f
end

# TODO: filters/converters/formats
# TODO: generators
