require_relative '../../test_helper'

require_relative Application.from_src('storage/memory')

class StorageMemoryTest < Minitest::Test
  def teardown
    Storage::Memory.clear!
  end

  def test_find
    Storage::Memory.save(self.class, 'id', 'response')

    assert_equal 'response', Storage::Memory.find(self.class, 'id')
  end

  def test_find_not_found
    assert_nil Storage::Memory.find(self.class, 'id')
  end

  def test_find_bang_not_found
    assert_raises(ArgumentError) { Storage::Memory.find!(self.class, 'id') }
  end

  def test_clear
    Storage::Memory.save(self.class, 'id', 'response')
    Storage::Memory.clear!

    assert_nil Storage::Memory.find(self.class, 'id')
  end
end
