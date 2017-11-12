require "test_helper"

class FileFilterTest < TestCase
  def test_no_ops_not_called
    filter = Lmkplz::FileFilter.new
    filter.call("", "", "") do
      raise "block should not have been called"
    end
  end

  def test_ops_are_called
    filter = Lmkplz::FileFilter.new
    filter.call("lol", "", "") do
      @called = true
    end

    assert_equal(true, @called)
  end

  def test_blank_paths_are_nil
    filter = Lmkplz::FileFilter.new
    filter.call("lol", "", "") do |modified, created, removed|
      @called = true

      assert_equal("lol", modified)
      assert_nil(created)
      assert_nil(removed)
    end

    assert_equal(true, @called)
  end

  def test_only_runs_and_filters_out_mismatches
    filter = Lmkplz::FileFilter.new(only: /lol/)
    filter.call("lol", "hi", "") do |modified, created, removed|
      @called = true

      assert_equal("lol", modified)
      assert_nil(created)
      assert_nil(removed)
    end

    assert_equal(true, @called)
  end

  def test_only_skips
    filter = Lmkplz::FileFilter.new(only: /lol/)
    filter.call("nope", "no", "never") { raise "block was called" }
  end

  def test_except_runs_and_filters_out_mismatches
    filter = Lmkplz::FileFilter.new(except: /lol/)
    filter.call("yes", "yup", "lol") do |modified, created, removed|
      @called = true

      assert_equal("yes", modified)
      assert_equal("yup", created)
      assert_nil(removed)
    end

    assert_equal(true, @called)
  end

  def test_except_skips
    filter = Lmkplz::FileFilter.new(except: /lol/)
    filter.call("lol", "lolol", "lololol") { raise "block was called" }
  end
end
