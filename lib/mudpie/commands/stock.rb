class MudPie::StockCommand

  MudPie::COMMANDS['stock'] = self

  def self.summary
    "Update pantry with pages and layouts"
  end

  def self.help
    "Usage: mudpie stock"
  end

  def self.call(argv, options)
    self.new.execute
  end

  def initialize(bakery = nil)
    @bakery = bakery || MudPie::Bakery.new
    @pantry = @bakery.pantry
  end

  def execute
    purge_rows_for_missing_files
    scan_pages(Pathname.new('layouts')) { |path| stock_layout path }
    scan_pages(Pathname.new('pages'))   { |path| stock_page path }
  end

  def scan_pages(dir, &block)
    dir.each_child do |path|
      if path.directory?
        scan_pages(path, &block)
      else
        record = @pantry.record_for_path(path)
        if record.nil?
          puts "NEW  #{path}"
          yield path
        elsif record[:mtime] < path.mtime
          puts "UPDA #{path}"
          yield path
        else
          puts "OK   #{path}" if MudPie::OPTIONS[:debug]
        end
      end
    end
  end

  def stock_layout(path)
    chain = MudPie::build_render_chain(path)
    name = '#' + path.basename.to_s.chomp(path.extname)
    @pantry.stock(path, name, chain.meta)
  end

  def stock_page(path)
    chain = MudPie::build_render_chain(path)
    @pantry.stock(path, chain.url, chain.meta)
  end

  def purge_rows_for_missing_files
    ids_to_purge = []
    @pantry.select_all("SELECT * FROM `pages`") do |row|
      path = Pathname.new(row[:source_path])
      unless path.exist?
        puts "DELE #{path}"
        ids_to_purge << row[:id]
      end
    end
    if ids_to_purge.length > 0
      @pantry.delete_pages_by_id(ids_to_purge)
    end
  end

end
