module MudPie::Loader
  LOADER_CLASSES = Array.new

  class BasicLoader
    attr_reader :source_path

    def initialize(source_path)
      @source_path = source_path
    end
  end

  def self.add_loader_class(loader_class)
    LOADER_CLASSES.insert 0, loader_class
  end

  def self.loader_for_path(path)
    loader_class = LOADER_CLASSES.find { |lc| lc.can_load_path?(path) }
    loader_class.new(path)
  end
end

require 'mudpie/loader/default' # should always be first
require 'mudpie/loader/front_matter'
