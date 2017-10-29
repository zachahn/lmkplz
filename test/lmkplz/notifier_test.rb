require "test_helper"

class NotifierTest < TestCase
  def test_it_works
    Thread.abort_on_exception = true
    logger = Logger.new($stdout)

    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        Timeout.timeout(5) do
          File.write(File.join(dir, "ensure_file_and_folder_created.txt"), "\n")
          sleep(0.01)

          events = Queue.new

          notifier =
            Lmkplz::Notifier.new(dir) do |modified, created, deleted|
              logger.info "pushed #{modified} #{created}, #{deleted}"
              events.push([modified, created, deleted])
            end

          logger.info "notifier initialized"

          notifier.start

          new_file_path = File.join(dir, "test.txt")
          File.write(new_file_path, "Hi\n")
          File.write(new_file_path, "Bye\n")

          logger.info "files written"

          loop do
            if events.size >= 2
              break
            end

            Thread.pass
          end

          notifier.pause

          puts events.inspect
        end
      end
    end
  end
end
