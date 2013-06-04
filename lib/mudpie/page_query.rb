class MudPie::PageQuery

  class SortDescriptor
    attr_reader :key
    def initialize(key, ascending = true)
      @key = key.to_sym
      @ascending = ascending
    end
    def to_sql
      "`#{@key}` " + (@ascending ? 'ASC' : 'DESC')
    end
  end

  class Predicate
    attr_reader :key
    attr_reader :value
    def initialize(key, operator, value)
      @key = key.to_sym
      @operator = operator
      @value = case value
      when Numeric, nil
        value
      else
        value.to_s
      end
    end
    def to_sql
      sql = "`#{@key}` #{@operator}"
      sql << ' ?' unless @value.nil?
      return sql
    end
  end

  def initialize(pantry, state = nil)
    @pantry = pantry
    @state = state || { where: [], order: [], limit: nil }
  end

  def where(*args)
    new_where = @state[:where].dup
    case args.length
    when 0
      raise "Where what?"
    when 1
      case args[0]
      when Hash
        args[0].each { |k,v| new_where << Predicate.new(k, '=', v) }
      when /^(\w+) ([!=<>]+) '(.+)'$/
        new_where << Predicate.new($1, $2, $3)
      when /^(\w+) ([!=<>]+) ([0-9]+)$/
        new_where << Predicate.new($1, $2, $3.to_i)
      when /^(\w+) (IS(?: NOT)? NULL)$/
        new_where << Predicate.new($1, $2, nil)
      else
        raise "Where? I don't understand: #{args}"
      end
    when 2
      if /(\w+) ([!=<>]+) \?$/.match(args[0])
        new_where << Predicate.new($1, $2, args[1])
      else
        raise "Where? I don't understand: #{args}"
      end
    else
      raise "Too many arguments, I don't know how to deal."
    end
    self.class.new(@pantry, @state.merge(where: new_where))
  end

  def order(*args)
    new_order = @state[:order].dup
    args.map(&:to_s).each do |arg|
      if /^(\w+) (ASC|DESC)$/i.match(arg)
        new_order << SortDescriptor.new($1, $2.upcase == 'ASC')
      elsif /^(\w+)$/.match(arg)
        new_order << SortDescriptor.new($1)
      else
        raise "I don't understand order by '#{arg}'"
      end
    end
    self.class.new(@pantry, @state.merge(order: new_order))
  end

  def limit(new_limit)
    self.class.new(@pantry, @state.merge(limit: new_limit))
  end

  def all
    @pantry.execute_page_query(self)
  end

  def first
    limit(1).all.first
  end

  def each(&block)
    all.each(&block)
  end

  def keys
    set = ::Set.new
    set.merge @state[:where].map(&:key)
    set.merge @state[:order].map(&:key)
  end

  def where_sql
    predicates = @state[:where]
    return [""] if predicates.size == 0
    sql = predicates.map(&:to_sql).join(' AND ')
    ['WHERE ' + sql].concat(predicates.map(&:value).compact)
  end

  def order_sql
    sort_descs = @state[:order]
    return "" if sort_descs.length == 0
    "ORDER BY " + sort_descs.map(&:to_sql).join(', ')
  end

  def limit_sql
    limit = @state[:limit]
    return "" if limit.nil?
    "LIMIT #{limit}"
  end

end
