require 'nokogiri'

class MudPie::WPXMLRenderer < MudPie::Renderer

  register '.wp-page', self
  register '.wp-post', self

  def read_meta(context, input)
    parse_input(input) do |xml|
      update_context(context, xml.root)
    end
  end

  def render(context, input, output)
    parse_input(input) do |xml|
      update_context(context, xml.root)
      output << xml.xpath('/item/content:encoded').text
    end
  end

  private

  def parse_input(input)
    xml = Nokogiri::XML::Document.parse(input) do |config|
      config.noblanks
    end
    yield xml
  end

  def update_context(context, root)
    context['title'] = root.xpath('title').text
    context['date'] = Time.parse root.xpath('pubDate').text
    context['wp_post_type'] = root.xpath('wp:post_type').text
  end

end
