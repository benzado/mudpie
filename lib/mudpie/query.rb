class MudPie::Query
  def initialize(pantry, where = {}, order = [], limit = nil)
    @pantry = pantry
    @where = where
    @order = order
    @limit = limit
  end

  def where(opts)
    self.class.new(@pantry, @where.merge(opts), @order, @limit)
  end

  def order(key)
    self.class.new(@pantry, @where, @order + [key], @limit)
  end

  def limit(n)
    self.class.new(@pantry, @where, @order, n)
  end

  def all
    @pantry.resources_for_sql(to_sql, bind_values).map do |resource|
      MudPie::Page.new(resource.metadata, resource.path)
    end
  end

  def each(&block)
    all.each(&block)
  end

  def to_sql
    sql = ""
    unless @where.empty?
      predicates = @where.keys.map { |key| @pantry.sql_for_key(key.to_s) + ' = ?' }
      sql << ' WHERE ' << predicates.join(' AND ')
    end
    unless @order.empty?
      clauses = @order.map do |t|
        name, direction = t.to_s.split(/ +/, 2)
        [@pantry.sql_for_key(name), direction].compact.join(' ')
      end
      sql << ' ORDER BY ' << clauses.join(', ')
    end
    unless @limit.nil?
      sql << " LIMIT #{@limit}"
    end
    return sql
  end

  def bind_values
    @where.values.map do |value|
      case value
      when Symbol then value.to_s
      else value
      end
    end
  end
end
