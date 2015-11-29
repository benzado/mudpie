require 'minitest/autorun'
require 'mudpie/query'

class TestQuery < MiniTest::Unit::TestCase
  def setup
    @pantry = MiniTest::Mock.new
    @query = MudPie::Query.new(@pantry)
  end

  def teardown
    @pantry.verify
  end

  def test_blank
    assert_equal "", @query.to_sql
    assert @query.bind_values.empty?
  end

  def test_where
    @pantry.expect(:sql_for_key, '`answer`', ['answer'])
    q = @query.where(answer: 42)
    assert_equal " WHERE `answer` = ?", q.to_sql
    assert_equal [42], q.bind_values
  end

  def test_where_2
    @pantry.expect(:sql_for_key, '`foo`', ['foo'])
    @pantry.expect(:sql_for_key, '`bar`', ['bar'])
    q = @query.where(foo: 1, bar: 2)
    assert_equal " WHERE `foo` = ? AND `bar` = ?", q.to_sql
    assert_equal [1, 2], q.bind_values
  end

  def test_where_where
    @pantry.expect(:sql_for_key, '`foo`', ['foo'])
    @pantry.expect(:sql_for_key, '`bar`', ['bar'])
    q = @query.where(foo: 1).where(bar: 2)
    assert_equal " WHERE `foo` = ? AND `bar` = ?", q.to_sql
    assert_equal [1, 2], q.bind_values
  end

  def test_order
    @pantry.expect(:sql_for_key, '`foo`', ['foo'])
    q = @query.order(:foo)
    assert_equal " ORDER BY `foo`", q.to_sql
    assert_equal [], q.bind_values
  end

  def test_order_asc
    @pantry.expect(:sql_for_key, '`foo`', ['foo'])
    q = @query.order('foo ASC')
    assert_equal " ORDER BY `foo` ASC", q.to_sql
    assert_equal [], q.bind_values
  end

  def test_order_desc
    @pantry.expect(:sql_for_key, '`foo`', ['foo'])
    q = @query.order('foo DESC')
    assert_equal " ORDER BY `foo` DESC", q.to_sql
    assert_equal [], q.bind_values
  end

  def test_limit_25
    q = @query.limit(25)
    assert_equal " LIMIT 25", q.to_sql
    assert_equal [], q.bind_values
  end

  def test_limit_25_limit_30
    q = @query.limit(25).limit(30)
    assert_equal " LIMIT 30", q.to_sql
    assert_equal [], q.bind_values
  end

  def test_limit_25_limit_nil
    q = @query.limit(25).limit(nil)
    assert_equal "", q.to_sql
    assert_equal [], q.bind_values
  end

  def test_order_limit_where
    @pantry.expect(:sql_for_key, '`suit`', ['suit'])
    @pantry.expect(:sql_for_key, '`rank`', ['rank'])
    q = @query.order(:rank).limit(10).where(suit: 'hearts')
    assert_equal " WHERE `suit` = ? ORDER BY `rank` LIMIT 10", q.to_sql
    assert_equal ['hearts'], q.bind_values
  end
end
