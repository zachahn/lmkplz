module Lmkplz
  class Interface
    def initialize
      @mutex = Mutex.new
      @add_queue = []

      @mutex.synchronize do
        @on_success = -> (_m, _a, _r) {}
        @on_failure = -> (_event, _path) {}
        @on_end = -> {}
      end
    end

    def on_success(&block)
      @mutex.synchronize do
        @on_success = block
      end
    end

    def on_failure(&block)
      @mutex.synchronize do
        @on_failure = block
      end
    end

    def start
      cwatch

      @mutex.synchronize do
        while @add_queue.any?
          add(@add_queue.pop)
        end
      end
    end

    def add(dir)
      if cwatch?
        Middleman.cwatch_add(cwatch, dir)
      else
        @mutex.synchronize do
          @add_queue.push(dir)
        end
      end
    end

    def await
      Middleman.cwatch_await(cwatch, @on_success, @on_failure, @on_end)
    end

    private

    def cwatch
      @cwatch ||= Middleman.cwatch_new(1)
    end

    def cwatch?
      !!@cwatch
    end
  end
end
