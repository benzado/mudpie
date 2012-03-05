module MudPie

class IncludeTag < Liquid::Tag

  def initialize(tag_name, file, tokens)
    super
    @file = file.strip
  end

  def render(context)
    site = context.registers[:site]
    path = File.join(site.config['includes_root'], @file)
    # TODO: validate path, looking for illegal characters
    if File.exists? path then
      source = File.read path
      partial = Liquid::Template.parse source
      context.stack do
        partial.render context
      end
    else
      "Included file #{path} not found."
    end
  end

end

end # module

Liquid::Template.register_tag('include', MudPie::IncludeTag)
