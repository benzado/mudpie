module MudPie::Renderer
  class RubyScript < BasicRenderer
    def rendered_content(context)
      context.content_type ||= 'text/html'
      output = StringIO.new
      begin
        oldout, $stdout = $stdout, output
        MudPie::ExecutionContext.new(context)._binding.eval(
          resource.content,
          resource.source_path.to_s
        )
      ensure
        $stdout = oldout
      end
      output.string
    end
  end

  add_renderer_class 'ruby-script', RubyScript
end
