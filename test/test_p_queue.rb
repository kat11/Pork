require 'minitest/autorun'
require 'p_queue'

class TestPQueue < MiniTest::Unit::TestCase
  def setup
    @queue = PQueue.new

    @queue.set :a, 10
    @queue.set :b, 5
    @queue.set :c, 15
    @queue.set :d, 20
  end

  def test_pop
    assert_equal 4, @queue.size
    assert_equal :b, @queue.pop.key
    assert_equal :a, @queue.pop.key
    assert_equal :c, @queue.pop.key
    assert_equal :d, @queue.pop.key
    assert_equal 0, @queue.size
    assert_nil @queue.pop
  end

  def test_change
    @queue.set :b, 12
    @queue.set :c, 11

    assert_equal :a, @queue.pop.key
    assert_equal :c, @queue.pop.key
    assert_equal :b, @queue.pop.key
    assert_equal :d, @queue.pop.key
    assert_equal 0, @queue.size
    assert_nil @queue.pop
  end

  def test_delete
    @queue.delete :b
    @queue.delete :d
    @queue.delete :x

    assert_equal 2, @queue.size
    assert_equal :a, @queue.pop.key
    assert_equal :c, @queue.top.key
    assert_equal :c, @queue.pop.key
    assert_nil @queue.pop
  end

end
