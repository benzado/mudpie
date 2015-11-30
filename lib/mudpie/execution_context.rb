require 'mudpie/page'
require 'mudpie/query'

class MudPie::ExecutionContext
  SERVED_HOT_KEY = '#SERVED_HOT'

  def initialize(context)
    @_context = context
  end

  def _binding
    binding
  end

  def embed_in_layout(layout_name)
    @_context.append_layout_name layout_name
  end

  def served_hot?
    @_context.metadata[SERVED_HOT_KEY]
  end

  def site
    # TODO: Implement
    @_site ||= MudPie::Page.new(title: 'Site Title')
  end

  def page
    @_page ||= MudPie::Page.new(@_context.metadata)
  end

  def pages
    MudPie::Query.new(@_context.pantry)
  end

  def date_to_http_format(date)
    DateTime.parse(date).httpdate
  end

  def content_tag(name, text, attributes)
    # TODO: escape v properly
    attrs = attributes.map {|n,v| %Q( #{n}="#{v}") }.join
    "<#{name}#{attrs}>#{text}</#{name}>"
  end

  def link_to(page)
    content_tag :a, page.title, href: page.path
  end
end