require "test_helper"

class MiddlemanTest < TestCase
  def test_it_works
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        cwatch = Lmkplz::Middleman.new_cwatch(1)
        Lmkplz::Middleman.add_cwatch(cwatch, dir)

        success_queue = Queue.new

        middleman =
          Thread.new do
            Lmkplz::Middleman.watch_cwatch(
              cwatch,
              -> (type, path) { success_queue.push([type, path]) },
              -> (_, _) {},
              -> {}
            )
          end

        consumer =
          Thread.new do
            success_queue.pop

            Thread.kill(middleman)
          end

        new_file_path = File.join(dir, "test.txt")
        File.write(new_file_path, "test!")

        consumer.join
        middleman.join
      end
    end
  end
end
