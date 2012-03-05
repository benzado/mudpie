module MudPie

  Formats = {}

  IdentityFormat = lambda { |item, text| text }

  Formats.default = IdentityFormat

if require 'markdown' then
  Formats['.md'] = Formats['.markdown'] = if require 'rubypants' then
    lambda { |item, text| RubyPants.new(Markdown.new(text).to_html).to_html }
  else
    lambda { |item, text| Markdown.new(text).to_html }
  end
end

  # TODO: add support for textile

end # module
