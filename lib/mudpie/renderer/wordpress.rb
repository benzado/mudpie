require 'nokogiri'

module MudPie::Renderer
  class WordPress < BasicRenderer
    # TODO: add smart quotes
    def ensmarten(text)
      text
    end

    def rendered_content(context)
      context.content_type = 'text/html'

      xml = Nokogiri::XML::Document.parse(resource.content) do |config|
        config.noblanks
      end

      root = xml.root
      context.merge_metadata(
        'title' => ensmarten(root.xpath('title').text),
        'date' => Time.parse(root.xpath('pubDate').text),
        'guid' => root.xpath('guid').text,
        'wp_post_type' => root.xpath('wp:post_type').text,
      )
      # TODO: Shouldn't hard code this, but need a good place to config it first.
      context.merge_metadata('layout' => 'blog-post') if context.metadata['wp_post_type'] == 'post'

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

      ensmarten dumb_paragraphs.join
    end
  end

  add_renderer_class 'wordpress', WordPress
end
