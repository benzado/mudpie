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
    @bakery.pantry.each_page do |page|
      path = Pathname.new(@bakery.output_root + page.url)
      outdated(path) do |path_gz|
        compress path, path_gz if compressable? page
      end
    end
    Pathname.new(@bakery.output_root).join('assets').each_child do |path|
      outdated(path) do |path_gz|
        compress path, path_gz if COMPRESSABLE_EXTNAMES.include?(path.extname)
      end
    end
  end

  def outdated(path)
    path_gz = Pathname.new(path.to_s + '.gz')
    if (!path_gz.exist? || path.mtime > path_gz.mtime)
      yield path_gz
    end
  end

  def compressable?(page)
    return false if EXCLUDE_URLS.include?(page.url)
    return true if COMPRESSABLE_EXTNAMES.include?(File.extname(page.url))
    # Compress MIME types:  text/___,  ___/xml,  ___/___+xml
    %r{^text/|[+/]xml(;|$)}.match(page.http_content_type)
  end

  def compress(path, path_gz)
    puts "GZIP #{path}"
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
