class MudPie::ExecutionContext
  SERVED_HOT_KEY = '#SERVED_HOT'

  attr_reader :_result

  def initialize(context)
    @_context = context
  end

  def _execute(erb)
    erb.result(binding)
  end

  def embed_in_layout(layout_name)
    @_context.append_layout_name layout_name
  end

  def served_hot?
    @_context.metadata[SERVED_HOT_KEY]
  end

  class Page
    def initialize(context)
      @context = context
    end

    def method_missing(symbol, *args)
      key = symbol.to_s
      if args.empty? && @context.metadata.has_key?(key)
        @context.metadata[key]
      else
        super(symbol, *args)
      end
    end
  end

  def page
    @_page ||= Page.new(@_context)
  end
end
