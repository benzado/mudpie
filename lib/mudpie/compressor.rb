require 'zlib'

module MudPie

class Compressor

  COMPRESSABLE = %w[.css .js .html .txt .xml]

  def initialize(config)
    @config = config
  end

  def compress_file(path)
    return unless COMPRESSABLE.include?(File.extname path)
    path_gz = path + ".gz"
    unless File.exists?(path_gz) and File.mtime(path) <= File.mtime(path_gz) then
      Zlib::GzipWriter.open(path_gz) do |gz|
        gz.write File.read(path)
      end
      File.utime(File.atime(path), File.mtime(path), path_gz)
      puts "Created #{path_gz}"
    end
#     # Serving raw deflated data is risky because of inconsistent browser support.
#     path_df = path + ".deflate"
#     unless File.exists?(path_df) and File.mtime(path) <= File.mtime(path_df) then
#       File.open(path_df, 'w') do |df|
#         df.write Zlib::Deflate.deflate(File.read(path), Zlib::BEST_COMPRESSION)
#       end
#       File.utime(File.atime(path), File.mtime(path), path_df)
#       puts "Created #{path_df}"
#     end
  end

  def compress_dir(dir)
    Dir.foreach(dir) do |name|
      next if name == '.' or name == '..'
      path = File.join(dir, name)
      if File.directory? path then
        compress_dir path
      else
        compress_file path
      end
    end
  end

  def compress_all
    compress_dir @config['destination']
  end

end

end # module
