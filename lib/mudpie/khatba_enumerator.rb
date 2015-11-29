# In Egyptian culture, a Khatba is a professional mediator or broker of
# relationships. A KhatbaEnumerator combines the output of two enumerators
# using a comparator. If the comparator says that the two values match, it
# yields the values together. Otherwise, it yields the lesser value and nil.
class MudPie::KhatbaEnumerator < Enumerator
  def initialize(a, b, &comparator)
    a = a.each unless a.respond_to?(:next)
    b = b.each unless b.respond_to?(:next)
    comparator = proc { |a, b| a <=> b } unless block_given?
    super() do |caller|
      loop do
        case comparator.call(a.peek, b.peek)
        when -1 then caller.yield [a.next, nil]
        when  0 then caller.yield [a.next, b.next]
        when  1 then caller.yield [nil, b.next]
        else raise ArgumentError, "KhatbaEnumerator: values #{a.peek.inspect} and #{b.peek.inspect} cannot be compared"
        end
      end
      loop { caller.yield [a.next, nil] }
      loop { caller.yield [nil, b.next] }
    end
  end
end
