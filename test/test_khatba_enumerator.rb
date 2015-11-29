require 'minitest/autorun'
require 'mudpie/khatba_enumerator'

describe MudPie::KhatbaEnumerator do
  describe 'when comparator returns nil' do
    let(:e) { MudPie::KhatbaEnumerator.new(1..9, 'A'..'Z') }

    it 'raises an error' do
      proc { e.next }.must_raise ArgumentError
    end
  end

  describe 'when a custom comparator block is provided' do
    let(:e) { MudPie::KhatbaEnumerator.new(65..90, 'A'..'Z') { |n,s| n <=> s.codepoints.first } }

    it 'works' do
      e.first(10).must_equal [
        [65, 'A'],
        [66, 'B'],
        [67, 'C'],
        [68, 'D'],
        [69, 'E'],
        [70, 'F'],
        [71, 'G'],
        [72, 'H'],
        [73, 'I'],
        [74, 'J'],
      ]
    end
  end

  describe 'when both enumerators are infinite' do
    let(:z) { (1..Float::INFINITY).lazy }
    let(:m2) { z.map { |z| z * 2 } }
    let(:m3) { z.map { |z| z * 3 } }
    let(:e) { MudPie::KhatbaEnumerator.new(m2, m3) }

    it 'works' do
      e.first(7).must_equal [
        [  2, nil],
        [nil,   3],
        [  4, nil],
        [  6,   6],
        [  8, nil],
        [nil,   9],
        [ 10, nil],
      ]
    end
  end

  describe 'when suffixes match' do
    let(:ape) { 'APE'.each_char }
    let(:grape) { 'GRAPE'.each_char }

    describe 'when shorter one is first' do
      let(:e) { MudPie::KhatbaEnumerator.new(ape, grape) }

      it 'exhausts both enumerators' do
        e.to_a.must_equal [
          ['A', nil],
          [nil, 'G'],
          ['P', nil],
          ['E', nil],
          [nil, 'R'],
          [nil, 'A'],
          [nil, 'P'],
          [nil, 'E'],
        ]
      end
    end

    describe 'when longer one is first' do
      let(:e) { MudPie::KhatbaEnumerator.new(grape, ape) }

      it 'exhausts both enumerators' do
        e.to_a.must_equal [
          [nil, 'A'],
          ['G', nil],
          [nil, 'P'],
          [nil, 'E'],
          ['R', nil],
          ['A', nil],
          ['P', nil],
          ['E', nil],
        ]
      end
    end

  end

  describe 'when prefixes match' do
    let(:startrek) { 'STARTREK'.chars }
    let(:starwars) { 'STARWARS'.chars }
    let(:e) { MudPie::KhatbaEnumerator.new(startrek, starwars) }

    it 'works' do
      e.to_a.must_equal [
        ['S', 'S'],
        ['T', 'T'],
        ['A', 'A'],
        ['R', 'R'],
        ['T', nil],
        ['R', nil],
        ['E', nil],
        ['K', nil],
        [nil, 'W'],
        [nil, 'A'],
        [nil, 'R'],
        [nil, 'S'],
      ]
    end
  end
end
