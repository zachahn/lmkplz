module Lmkplz
  class Notifier
    def initialize(*paths)
      @paths = paths

      @cwatch = Middleman.new_cwatch(1)
      @paths.each { |path| Middleman.add_cwatch(@cwatch, path) }

      @callbacks = {}

      @mutex = Mutex.new
      @files = Queue.new

      @callbacker = Thread.new do
        loop do
          type, file = @files.pop

          @mutex.synchronize do
            callback = @callbacks[type]

            if callback
              callback.call(path)
            end
          end
        end
      end
    end

    def callbacker
      @callbacker
    end

    def on_create(&block)
      @mutex.synchronize do
        @callbacks["create"] = block
      end
    end

    def on_write(&block)
      @mutex.synchronize do
        @callbacks["write"] = block
      end
    end

    def on_remove(&block)
      @mutex.synchronize do
        @callbacks["remove"] = block
      end
    end

    def start
      @watcher_thread ||= Thread.new(&method(:init_middleman_watch))

      nil
    end

    def watcher_thread
      @watcher_thread
    end

    def kill
      Thread.kill(@watcher_thread)

      nil
    end

    private

    def init_middleman_watch
      Middleman.watch_cwatch(
        @cwatch,
        method(:middleman_callback).to_proc,
        -> (_, _) {},
        -> {}
      )
    end

    def middleman_callback(type, path)
      @mutex.synchronize do
        @queue.push([type, path])
      end
    end
  end
end
