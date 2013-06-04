class MudPie::PageContext

  include Enumerable

  PROTECTED_VARIABLES = [:@_page]

  def initialize(page, hsh = nil)
    @_page = page
    hsh.each { |key, value| self[key] = value } if hsh
  end

  def get_binding
    binding
  end

  def [](name)
    key = ("@#{name}").to_sym
    raise NameError if PROTECTED_VARIABLES.include?(key)
    instance_variable_get(key) if instance_variable_defined?(key)
  end

  def []=(name, value)
    key = ("@#{name}").to_sym
    raise NameError if PROTECTED_VARIABLES.include?(key)
    instance_variable_set(key, value)
  end

  def each
    instance_variables.each do |key|
      unless PROTECTED_VARIABLES.include?(key)
        name = key[1..-1].to_sym
        yield name, instance_variable_get(key)
      end
    end
  end

  def url
    @_page.url
  end

  def mtime
    @_page.mtime
  end

  def content
    @_page.render
  end

  def site
    @_page.pantry.bakery.site
  end

  def served_hot?
    @_page.pantry.bakery.serve_hot?
  end

  def pages
    @_page.pantry.pages
  end

  # TODO: move these helpers into another class/module

  def absolute_url(path = @_page.url)
    File.join(@_page.pantry.bakery.site.base_url, path).sub(%r{/index.html$}, '/')
  end

  def xml_escape(input)
    input.gsub(/[<&>]/) {|c| '&#x%x;' % c.ord }
  end

  def parse_entities(input)
    input.gsub(/&#(\d+);/) {|d| $1.to_i.chr(Encoding::UTF_8) }.gsub('&amp;','&')
  end

  def date_to_http_format(date)
    DateTime.parse(date).httpdate
  end

  def content_tag(tag_name, *args)
    html = "<#{tag_name}"
    if args.last.is_a?(Hash)
      attributes = args.pop
      attributes.each do |name, value|
        html << sprintf(' %s="%s"', name, xml_escape(value.to_s))
      end
    end
    content = if args.length > 0
      args.join
    elsif block_given?
      yield
    end
    if content
      html << sprintf('>%s</%s>', content, tag_name)
    else
      html << '/>'
    end
    return html
  end

  def asset_path(path)
    if asset = @_page.pantry.bakery.sprockets_environment.find_asset(path)
      File.join('/assets', asset.digest_path)
    else
      raise "Cannot find asset for path `#{path}`"
    end
  end

  def stylesheet_asset_link(path)
    content_tag :link, :href => asset_path(path), :rel => 'stylesheet'
  end

  def javascript_asset_link(path)
    content_tag(:script, '', :src => asset_path(path), :type => 'text/javascript')
  end

  def meta_tag(property, content)
    content_tag(:meta, :property => property, :content => content)
  end

  def link_to(subject, url = nil)
    if subject.is_a? MudPie::PageContext
      text = subject.title
      url = subject.url if url.nil?
    else
      text = subject.to_s
    end
    content_tag(:a, text, href: url)
  end

  # See https://en.wikipedia.org/wiki/List_of_XML_and_HTML_character_entity_references
  NAMED_ENTITIES = {
    '&lsquo;' => "\u2018", '&rsquo;' => "\u2019",
    '&ldquo;' => "\u201c", '&rdquo;' => "\u201d",
    '&nbsp;' => "\u00a0",
    '&copy;' => "\u00a9",
    '&ndash;' => "\u2013",
    '&mdash;' => "\u2014",
    '&hellip;' => "\u2026",
    '&lt;' => '<', '&gt;' => '>',
    '&quot;' => '"',
    '&apos;' => "'",
    '&amp;' => '&'
  }

  def strip_html(html)
    html.gsub(/<.*?>/, '').gsub(/&\w+;/, NAMED_ENTITIES).gsub(/\n{3,}/, "\n\n")
  end

  def include(subpath)
    path = File.join('parts', subpath)
    input = File.open(path, 'r')
    MudPie::Renderer.for_path(path).each do |r|
      output = StringIO.new
      r.render(self, input, output)
      input.close
      input = output
      input.rewind
    end
    input.read
  end

  private

  def method_missing(name, *args)
    if /^(\w+)=$/ =~ name
      super(name, *args) unless args.length == 1
      self[$1] = args[0]
    elsif /^(\w+)$/ =~ name
      super(name, *args) unless args.length == 0
      self[$1]
    else
      super.method_missing name, args
    end
  end

end
