$USE_DEBUG_KKTTYL = true # Must be set before Lmkplz::Metal is loaded

$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "lmkplz"

require "tmpdir"
require "timeout"
require "minitest/autorun"
require "pry-byebug"

class TestCase < Minitest::Test
end
