class MudPie::Page
  attr_reader :path

  def initialize(metadata, path = nil)
    @metadata = metadata
    @path = path
  end

  def method_missing(symbol, *args)
    key = symbol.to_s
    if args.empty? && @metadata.has_key?(key)
      @metadata[key]
    else
      MudPie.logger.warn "undefined metadata attribute '#{key}'"
      nil
      # super(symbol, *args)
    end
  end
end
