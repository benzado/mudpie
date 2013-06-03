class MudPie::BakeCommand

  MudPie::COMMANDS['bake'] = self

  def self.summary
    "Render pages"
  end

  def self.help
    "Usage: mudpie bake"
  end

  def self.call(argv, options)
    self.new.execute
  end

  def initialize
    @bakery = MudPie::Bakery.new
  end

  def execute
    @bakery.pantry.each_page do |page|
      target_path = Pathname.new('public' + page.url)
      # TODO: check dependencies (layouts), too
      if !target_path.exist? || page.mtime > target_path.mtime
        puts "BAKE #{page.url}"
        page.render_to(target_path)
      else
        puts "OK   #{page.url}" if MudPie::OPTIONS[:debug]
      end
    end
  end

end
