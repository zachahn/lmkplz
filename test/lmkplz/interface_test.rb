require "test_helper"

class InterfaceTest < TestCase
  def test_kkttyl_ruby_interface
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, "ensure_file_and_folder_created.txt"), "\n")
      sleep(0.01)
      queue = Queue.new
      interface = Lmkplz::Interface.new
      interface.add(dir)
      interface.on_success { |m, a, r| queue.push([m, a, r]) }

      interface.start

      new_file_path = File.join(dir, "test.txt")
      File.write(new_file_path, "test!")

      interface.await

      mod, add, del = queue.pop

      assert_equal("", mod)
      assert_match(new_file_path, add)
      assert_equal("", del)
    end
  end
end
