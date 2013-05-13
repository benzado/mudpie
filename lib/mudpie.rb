require 'set'
require 'stringio'
require 'builder'

module MudPie
  VERSION = '2.1'
  GEM_ROOT = File.expand_path('..', File.dirname(__FILE__))
end

require 'mudpie/compressor'
require 'mudpie/page_context'
require 'mudpie/page'
require 'mudpie/layout'
require 'mudpie/bakery'
require 'mudpie/pantry'
require 'mudpie/page_query'

require 'mudpie/renderer'
require 'mudpie/renderer/erb_renderer'
require 'mudpie/renderer/markdown_renderer'
require 'mudpie/renderer/ruby_renderer'
