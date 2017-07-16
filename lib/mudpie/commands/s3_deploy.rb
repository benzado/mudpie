require 'aws-sdk-v1'
require 'pathname'

class MudPie::S3DeployCommand

  MudPie::COMMANDS['s3:deploy'] = self

  def self.summary
    "Deploy to an S3 bucket"
  end

  def self.help
    "Usage: mudpie s3:deploy"
  end

  def self.call(argv, options)
    self.new(MudPie::Bakery.new).execute
  end

  def self.list_bucket(bucket_name)
    client = AWS::S3::Client.new
    options = { :bucket_name => bucket_name }
    done = false
    until done do
      list = client.list_objects(options)
      list[:contents].each do |item|
        unless options[:marker] == item[:key]
          yield item
        end
      end
      if list[:truncated]
        options[:marker] = list[:contents].last[:key]
      else
        done = true
      end
    end
  end

  class PageFile

    attr_reader :content_encoding
    attr_reader :key
    attr_reader :pathname

    attr_accessor :remote_etag
    attr_accessor :remote_mtime
    attr_accessor :remote_size

    def self.from_page(page)
      key = page.url.slice(1, page.url.length - 1)
      path = page.pantry.bakery.output_root + page.url
      self.new(key, path, page)
    end

    def self.from_path(path)
      key = path.sub(%r{^[^/]*/}, '')
      self.new(key, path, nil)
    end

    def initialize(key, path, page)
      @key = key
      @page = page
      pathname_gz = Pathname.new(path + '.gz')
      if pathname_gz.file?
        @content_encoding = 'gzip'
        @pathname = pathname_gz
      else
        @content_encoding = nil
        @pathname = Pathname.new(path)
      end
    end

    CONTENT_TYPES = {
      '.css'  => 'text/css; charset=UTF-8',
      '.gif'  => 'image/gif',
      '.html' => 'text/html; charset=UTF-8',
      '.ico'  => 'image/x-icon',
      '.jpeg' => 'image/jpeg',
      '.jpg'  => 'image/jpeg',
      '.js'   => 'application/javascript',
      '.json' => 'application/json',
      '.pdf'  => 'application/pdf',
      '.pl'   => 'text/plain; charset=UTF-8',
      '.plist'=> 'application/x-plist',
      '.png'  => 'image/png',
      '.rtf'  => 'text/rtf',
      '.safariextz' => 'application/octet-stream',
      '.txt'  => 'text/plain; charset=UTF-8',
      '.xml'  => 'text/xml; charset=UTF-8',
      '.zip'  => 'application/zip'
    }

    DEFAULT_CONTENT_TYPE = 'application/octet-stream'

    def content_type
      CONTENT_TYPES[File.extname(@key)] ||
      begin
        @page.http_content_type if @page
      end ||
      begin
        puts "WARNING: cannot detect Content-Type for #{@key}"
        DEFAULT_CONTENT_TYPE
      end
    end

    def update_needed?
      @remote_etag.nil? || size_mismatch? || content_mismatch?
    end

    def size_mismatch?
      @pathname.size != @remote_size
    end

    def content_mismatch?
      @remote_etag != local_etag
    end

    def local_etag
      @local_etag ||= begin
        digest = OpenSSL::Digest::MD5.new
        buffer = String.new
        @pathname.open('rb') do |f|
          while not f.eof?
            f.readpartial(1024, buffer)
            digest << buffer
          end
        end
        '"' + digest.digest.unpack('H*').first + '"'
      end
    end

    def to_s
      sprintf('%10d %-4s %-20s %s', @pathname.size, @content_encoding, content_type, @key)
    end

  end

  def initialize(bakery)
    config = YAML.load(File.read('aws.yml'))
    AWS.config(config)
    @bucket_name = config['bucket_name']
    @bakery = bakery
    if MudPie::OPTIONS[:debug]
      $stderr.puts "S3 Access Key ID: #{config['access_key_id']}"
      $stderr.puts "S3 Bucket: #{@bucket_name}"
    end
  end

  def execute
    page_files = Hash.new

    @bakery.pantry.each_page do |page|
      pf = PageFile.from_page(page)
      page_files[pf.key] = pf
    end
    Dir.glob('public/assets/**/*') do |path|
      unless File.extname(path) == '.gz'
        pf = PageFile.from_path(path)
        page_files[pf.key] = pf
      end
    end

    keys_to_delete = Array.new

    self.class.list_bucket(@bucket_name) do |item|
      key = item[:key]
      if pf = page_files[key]
        pf.remote_etag = item[:etag]
        pf.remote_mtime = item[:last_modified]
        pf.remote_size = item[:size].to_i
      else
        keys_to_delete << key
      end
    end

    s3 = AWS::S3.new
    bucket = s3.buckets[@bucket_name]
    remote_objects = bucket.objects
    page_files.values.each do |pf|
      if pf.update_needed?
        puts "UPLO #{pf.key}"
        remote_objects[pf.key].write(pf.pathname, {
          :acl => :public_read,
          :content_type => pf.content_type,
          :content_encoding => pf.content_encoding,
          # :content_md5 => a base64 encoded MD5 hash of the data
          # :cache_control => ''
        })
      else
        puts "SKIP #{pf.key}" if MudPie::OPTIONS[:debug]
      end
    end

    if keys_to_delete.size > 0
      keys_to_delete.each { |k| puts "DELE #{k}" }
      bucket.objects.delete(keys_to_delete)
    end
  end

end
