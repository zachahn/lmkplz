module Lmkplz
  class Notifier
    attr_reader :callbacker

    def initialize(*paths)
      @paths = paths
      @logger = Logger.new($stdout)

      # Initialize cwatch
      @cwatch = Middleman.new_cwatch(1)
      @paths.each { |path| Middleman.add_cwatch(@cwatch, path) }

      @callbacks = {}

      @mutex = Mutex.new
      @files = Queue.new
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
      @logger.debug "! starting the middleman"
      @watcher_thread ||= Thread.new(&method(:init_middleman_watch))
      @logger.debug "! started the middleman"
      Thread.pass

      @callbacker = Thread.new do
        @logger.debug "! callbacker started"
        loop do
          Thread.pass
          @logger.debug "! callbacker loop"
          type, file = @files.pop
          @logger.debug "! callbacker file pop"

          @mutex.synchronize do
            @logger.debug "! calling callback"
            callback = @callbacks[type]

            if callback
              callback.call(path)
            end
            @logger.debug "! call callback finished"
          end
        end
      end

      @logger.debug "! created the callbacker"

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
      @queue.push([type, path])
    end
  end
end
