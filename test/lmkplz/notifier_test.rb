require "test_helper"

class NotifierTest < TestCase
  def test_it_works
    Thread.abort_on_exception = true
    logger = Logger.new($stdout)

    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        new_file_path = File.join(dir, "test.txt")
        File.write(new_file_path, "\n")
        logger.debug "wrote new file"

        modified_files = Queue.new
        callback = -> (path) { modified_files.push(path) }

        waiter = Thread.new do
          logger.debug "inside the waiter/killer"
          modified_files.pop
          logger.debug "popped modified file"
          notifier.kill
          logger.debug "killed notifier"
        end

        logger.debug "initializing notifier"

        notifier = Lmkplz::Notifier.new(dir)
        notifier.on_write(&callback)
        notifier.on_create(&callback)
        notifier.on_remove(&callback)

        logger.debug "initialized notifier"

        notifier.start

        logger.debug "started notifier"

        File.write(new_file_path, "test!\n")

        logger.debug "updated file"

        # notifier.callbacker.join
        puts modified_files.size
        puts modified_files.num_waiting
        waiter.join
        notifier.watcher_thread

        puts 7
      end
    end
  end
end
