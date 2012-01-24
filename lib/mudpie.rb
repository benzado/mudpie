# rubygems
require 'rubygems'

# stdlib
require 'fileutils'
require 'yaml'

# dependencies
require 'liquid'
require 'sqlite3'

# equip the kitchen
require 'mudpie/command'
require 'mudpie/config'
require 'mudpie/filters'
require 'mudpie/index'
require 'mudpie/index_entry'
require 'mudpie/page_set'
require 'mudpie/server'
require 'mudpie/site'
require 'mudpie/source_file'
  require 'mudpie/page'
  require 'mudpie/layout'

module MudPie
	VERSION = '2.0'
end

# tags
glob = File.join(File.dirname(__FILE__), 'mudpie/tags/*.rb')
Dir[glob].each do |f|
	require f
end
