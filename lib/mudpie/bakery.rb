require 'sprockets'

class MudPie::Bakery

  attr_accessor :output_root

  def initialize
    @output_root = 'public'
  end

  def pantry
    @pantry ||= MudPie::Pantry.new(self)
  end

  def sprockets_environment
    @sprockets ||= begin
      env = Sprockets::Environment.new
      env.append_path 'assets/javascripts'
      env.append_path 'assets/stylesheets'
      env
    end
  end

  def sprockets_assets
    assets = Array.new
    %w( assets/javascripts assets/stylesheets ).each do |dir|
      Pathname.new(dir).each_child do |asset|
        if asset.file?
          $stderr.puts "ASSET #{asset.basename}" if MudPie::OPTIONS[:debug]
          assets << asset.basename
        end
      end
    end
    assets
  end

  def page_for_url(url)
    pantry.page_for_url(url)
  end

  def site
    @site ||= begin
      load 'site.rb'
      site = Object.new
      site.extend(::Site)
      site
    end
  end

  def serve_hot?
    @is_hot || false
  end

  def serve_hot!
    @is_hot = true
  end

end
