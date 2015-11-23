require 'erb'
require 'mudpie/execution_context'

module MudPie::Layout
  class ERB < BasicLayout
    SAFE_LEVEL = nil
    TRIM_MODE = '%'

    def initialize(path)
      @erb = ::ERB.new(path.read, SAFE_LEVEL, TRIM_MODE)
      @erb.filename = path.to_s
    end

    def render(context, content)
      MudPie::ExecutionContext.new(context)._execute(@erb) { content }
    end
  end

  add_layout_class '.erb', ERB
end
