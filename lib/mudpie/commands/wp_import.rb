require 'net/http'
require 'nokogiri'
require 'pathname'
require 'uri'

class MudPie::WordPressImporter

  MudPie::COMMANDS['wp:import'] = self

  def self.summary
    "Import a WordPress Export XML file"
  end

  def self.help
    "Usage: mudpie wp:import <path-to-wordpress-xml>"
  end

  def self.call(argv, options)
    raise "Must specify a WordPress XML file!" unless argv.length > 0
    self.new(argv[0]).import!
  end

  def initialize(wr_xml_path)
    @xml = Nokogiri::XML::Document.parse(File.open(wr_xml_path, 'r')) do |config|
      config.noblanks
    end
  end

  def import!
    # /rss/channel/wp:author
    # /rss/channel/wp:category
    # /rss/channel/wp:tag
    @xml.xpath('/rss/channel/item').each do |item|
      import_item(item)
    end
  end

  private

  def warn(*args)
    $stderr.puts args.join(' ')
  end

  def debug?
    MudPie::OPTIONS[:debug]
  end

  def dry_run?
    MudPie::OPTIONS[:dry_run]
  end

  def pathname_for_url(url, ext = '')
    Pathname.new(File.join('pages', url.path + ext))
  end

  def create_or_update_path(path)
    unless dry_run?
      path.dirname.mkpath
      path.open('w') do |f|
        yield f
      end
    end
  end

  def download(url, path)
    headers = Hash.new
    if path.exist?
      headers['If-Modified-Since'] = path.mtime.httpdate
    end
    @client ||= Net::HTTP.new(url.host, url.port)
    @client.request_get(url.path, headers) do |response|
      if response.code == '200'
        content_length = response['Content-Length'].to_i
        have_length = 0
        create_or_update_path(path) do |f|
          response.read_body do |chunk|
            f.write(chunk)
            have_length += chunk.length
            printf("\r%3d%% %s", (100 * have_length) / content_length, path)
          end
        end
        printf("\r100%% %s\n", path)
        if last_modified = response['Last-Modified']
          t = Time.parse last_modified
          path.utime(t, t) unless dry_run?
        end
      elsif response.code == '304'
        printf("have %s\n", path)
      else
        warn "HTTP #{response.code} for #{url}"
      end
    end
  end

  def import_item(item)
    if item.xpath('wp:attachment_url').empty?
      import_page_item(item)
    else
      import_attachment_item(item)
    end
  end

  def import_page_item(item)
    page_url = URI.parse item.xpath('link').text
    extname = '.wp-' + item.xpath('wp:post_type').text
    path = pathname_for_url(page_url, extname)
    page_doc = Nokogiri::XML::Document.new
    page_doc.root = item.clone
    create_or_update_path(path) do |f|
      page_doc.write_xml_to f
    end
  end

  def import_attachment_item(item)
    attachment_url = URI.parse item.xpath('wp:attachment_url').text
    path = pathname_for_url(attachment_url)
    download(attachment_url, path)
  end

end
