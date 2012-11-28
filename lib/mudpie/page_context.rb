class MudPie::PageContext

  include Enumerable

  PROTECTED_VARIABLES = [:@_bakery, :@_page]

  def initialize(bakery, page, hsh = nil)
    @_bakery = bakery
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
    @_bakery.site
  end

  def served_hot?
    @_bakery.serve_hot?
  end

  def pages
    @_bakery.pantry.pages
  end

  # TODO: move these helpers into another class/module

  def absolute_url(path)
    File.join(@_bakery.site.base_url, path).sub(%r{/index.html$}, '/')
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
