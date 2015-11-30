class MudPie::Page
  def initialize(metadata)
    @metadata = metadata
  end

  def absolute_url
    # TODO: fetch base URL from config, or default metadata
    "http://localhost:4000" + @metadata['path']
  end

  def method_missing(symbol, *args)
    key = symbol.to_s
    if args.empty? && @metadata.has_key?(key)
      @metadata[key]
    else
      MudPie.logger.warn "undefined metadata attribute '#{key}'"
      nil
    end
  end
end
