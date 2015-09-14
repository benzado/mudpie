require 'erb'

module MudPie::Layout
  class ERB < BasicLayout
    SAFE_LEVEL = nil
    TRIM_MODE = '%'

    def initialize(path)
      @erb = ::ERB.new(path.read, SAFE_LEVEL, TRIM_MODE)
      @erb.filename = path.to_s
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

    class ExecutionContext
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

      def page
        @_page ||= Page.new(@_context)
      end
    end

    def render(context, content)
      ExecutionContext.new(context)._execute(@erb) { content }
    end
  end

  add_layout_class '.erb', ERB
end
