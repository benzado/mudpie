require 'nokogiri'
require 'redcarpet'

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
      raw_text = xml.xpath('/item/content:encoded').text
      # Strip enclosing <div> element
      %r[\A<div>(.+)</div>\Z]m.match(raw_text) do |m|
        raw_text = m[1]
      end
      # Split into paragraphs
      dumb_paragraphs = raw_text.split(/\n\n/).collect do |text|
        # Remove WordPress [caption] pseudo-tag
        /\A\[caption .+\](<img .+\/>)\[\/caption\]\Z/.match(text) do |m|
          text = m[1]
        end
        "<p>#{text}</p>\n" if text != ""
      end
      output << Redcarpet::Render::SmartyPants.render(dumb_paragraphs.join)
    end
  end

  private

  def parse_input(input)
    xml = Nokogiri::XML::Document.parse(input) do |config|
      config.noblanks
    end
    yield xml
  end

  ENTITIES = {
    '&amp;'    => '&',
    '&ldquo;'  => "\u201c",
    '&rdquo;'  => "\u201d",
    '&lsquo;'  => "\u2018",
    '&rsquo;'  => "\u2019",
    '&copy;'   => "\u00a9",
    '&trade;'  => "\u2122",
    '&reg;'    => "\u00ae",
    '&hellip;' => "\u2026",
    '&frac14;' => "\u00bc",
    '&frac12;' => "\u00bd",
    '&frac34;' => "\u00be",
    '&mdash;'  => "\u2014",
    '&ndash;'  => "\u2013"
  }

  def ensmarten(text)
    smart_text = Redcarpet::Render::SmartyPants.render(text)
    smart_text.gsub(/&[a-z]+;/) { |n| ENTITIES[n] or raise "Unknown entity #{n} from SmartyPants." }
  end

  def update_context(context, root)
    context['title'] = ensmarten root.xpath('title').text
    context['date'] = Time.parse root.xpath('pubDate').text
    context['guid'] = root.xpath('guid').text
    context['wp_post_type'] = root.xpath('wp:post_type').text
    # TODO: Shouldn't hard code this, but need a good place to config it first.
    context['collection'] = :blog if context['wp_post_type'] == 'post'
  end

end
