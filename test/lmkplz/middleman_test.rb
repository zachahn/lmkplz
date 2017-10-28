require "test_helper"

class MiddlemanTest < TestCase
  def test_it_works
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        File.write(File.join(dir, "ensure_file_and_folder_created.txt"), "\n")
        sleep(0.01)

        success_queue = Queue.new

        cwatch = Lmkplz::Middleman.cwatch_new(1)
        Lmkplz::Middleman.cwatch_add(cwatch, dir)

        new_file_path = File.join(dir, "test.txt")
        File.write(new_file_path, "test!")

        Lmkplz::Middleman.cwatch_await(
          cwatch,
          -> (mod, add, del) { success_queue.push([mod, add, del]) },
          -> (_, _) {},
          -> {}
        )

        mod, add, del = success_queue.pop

        assert_equal("", mod)
        assert_match(new_file_path, add)
        assert_equal("", del)
      end
    end
  end
end
