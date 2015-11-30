require 'nokogiri'
require 'psych'

module MudPie::Loader
  class WordPress < BasicLoader
    def self.can_load_path?(path)
      %w[.wp-page .wp-post].include? path.extname
    end

    def path
      super.chomp(source_path.extname)
    end

    def load_resource
      source = source_path.read

      xml = Nokogiri::XML::Document.parse(source) do |config|
        config.noblanks
      end
      meta = Hash.new
      meta['title'] = xml.root.xpath('title').text
      meta['date'] = Time.parse xml.root.xpath('pubDate').text
      meta['guid'] = xml.root.xpath('guid').text
      meta['wp_post_type'] = xml.root.xpath('wp:post_type').text
      # TODO: Shouldn't hard code this, but need a good place to config it first.
      meta['collection'] = 'blog' if meta['wp_post_type'] == 'post'

      MudPie::Resource.new(
        'path'          => path,
        'renderer_name' => 'wordpress',
        'metadata_yaml' => Psych.dump(meta),
        'content'       => source
      )
    end
  end

  add_loader_class WordPress
end
