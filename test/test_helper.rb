$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "lmkplz"

require "tmpdir"
require "minitest/autorun"
require "pry-byebug"

class TestCase < Minitest::Test
end
