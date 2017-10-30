module Lmkplz
  class Interface
    def initialize(gather_event_duration_ms)
      @mutex = Mutex.new
      @add_queue = []
      @gather_event_duration_ms = gather_event_duration_ms

      @mutex.synchronize do
        @on_success = -> (_m, _a, _r) {}
        @on_failure = -> {}
        @on_timeout = -> {}
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

    def on_timeout(&block)
      @mutex.synchronize do
        @on_timeout = block
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
        Metal.cwatch_add(cwatch, dir)
      else
        @mutex.synchronize do
          @add_queue.push(dir)
        end
      end
    end

    def await(wait_ms)
      if !cwatch?
        raise "Call #start before #await"
      end

      Metal.cwatch_await(
        cwatch,
        wait_ms,
        @on_success,
        @on_failure,
        @on_timeout,
        @on_end
      )
    end

    private

    def cwatch
      @cwatch ||= Metal.cwatch_new(@gather_event_duration_ms)
    end

    def cwatch?
      !!@cwatch
    end
  end
end
