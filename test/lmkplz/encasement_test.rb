require "test_helper"

class EncasementTest < TestCase
  def test_kkttyl_ruby_interface
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, "ensure_file_and_folder_created.txt"), "\n")
      sleep(0.01)
      queue = Queue.new
      interface = Lmkplz::Encasement.new
      interface.add(dir)
      interface.on_success { |m, c, r| queue.push([m, c, r]) }

      interface.start

      new_file_path = File.join(dir, "test.txt")
      File.write(new_file_path, "test!")
      sleep(0.01)

      while queue.size == 0
        interface.await
      end

      mod, add, del = queue.pop

      assert_equal("", mod)
      assert_match(new_file_path, add)
      assert_equal("", del)

      interface.free
    end
  end
end
