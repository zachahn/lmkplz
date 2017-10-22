require "test_helper"

class NotifierTest < TestCase
  def test_it_works
    Thread.abort_on_exception = true

    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        modified_files = Queue.new
        callback = -> (path) { modified_files.push(path) }

        puts 1

        notifier = Lmkplz::Notifier.new(dir)
        notifier.on_write(&callback)
        notifier.on_create(&callback)
        notifier.on_remove(&callback)
        notifier.start

        puts 4

        waiter = Thread.new do
          puts 5
          modified_files.pop
          notifier.kill
        end

        puts 6

        new_file_path = File.join(dir, "test.txt")
        File.write(new_file_path, "test!")

        puts 8

        notifier.callbacker.join
        waiter.join
        notifier.watcher_thread

        puts 7
      end
    end
  end
end
