require 'zlib'

class MudPie::Compressor

  COMPRESSABLE_EXTNAMES = %w[.css .js .html .txt .xml]

  attr_reader :compressed_files

  def initialize(filelist)
    @compressed_files = Rake::FileList.new
    filelist.each do |path|
      if compressable_path?(path)
        @compressed_files.include(path + '.gz')
      end
    end
  end

  def compressable_path?(path)
    COMPRESSABLE_EXTNAMES.include?(File.extname(path))
  end

  def uncompressed_path(gzpath)
    gzpath.chomp('.gz')
  end

  def compress(path, path_gz)
    puts "Compressing #{path}"
    Zlib::GzipWriter.open(path_gz) do |gz|
      gz.write File.read(path)
    end
    File.utime(File.atime(path), File.mtime(path), path_gz)
  end

end
