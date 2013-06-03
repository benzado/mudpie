require 'zlib'

class MudPie::CompressCommand

  MudPie::COMMANDS['compress'] = self

  def self.summary
    "Compress generated files"
  end

  def self.help
    "Usage: mudpie compress"
  end

  def self.call(argv, options)
    self.new(MudPie::Bakery.new).execute
  end

  COMPRESSABLE_EXTNAMES = %w[.css .js .html .txt .xml]
  EXCLUDE_URLS = %w[/robots.txt]

  def initialize(bakery)
    @bakery = bakery
  end

  def execute
    @bakery.pantry.select_all_pages do |page|
      path = Pathname.new(@bakery.output_root + page.url)
      path_gz = Pathname.new(@bakery.output_root + page.url + '.gz')
      if (!path_gz.exist? || path.mtime > path_gz.mtime) && compressable?(page)
        puts "GZIP #{page.url}"
        compress(path, path_gz)
      else
        puts "OK   #{page.url}" if MudPie::OPTIONS[:debug]
      end
    end
  end

  def compressable?(page)
    return false if EXCLUDE_URLS.include?(page.url)
    return true if COMPRESSABLE_EXTNAMES.include?(File.extname(page.url))
    # Compress MIME types:  text/___,  ___/xml,  ___/___+xml
    %r{^text/|[+/]xml(;|$)}.match(page.http_content_type)
  end

  def compress(path, path_gz)
    Zlib::GzipWriter.open(path_gz.to_s) do |gz|
      gz.mtime = path.mtime
      gz.orig_name = path.basename.to_s
      path.open('r') do |f|
        while chunk = f.read(1024)
          gz.write chunk
        end
      end
    end
    path_gz.utime(path.atime, path.mtime)
  end

end
