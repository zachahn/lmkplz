module Lmkplz
  class K
    def initialize
      @mutex = Mutex.new
      @add_queue = []
      @gather_event_duration_ms = 200

      @mutex.synchronize do
        @on_success = -> (_m, _c, _r) {}
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
      kkttyl

      @mutex.synchronize do
        while @add_queue.any?
          add(@add_queue.pop)
        end
      end
    end

    def free
      if !active?
        return
      end

      Metal.kkttyl_free(kkttyl)
      @kkttyl = nil
    end

    def add(dir)
      if active?
        Metal.kkttyl_add(kkttyl, dir)
      else
        @mutex.synchronize do
          @add_queue.push(dir)
        end
      end
    end

    def await
      if !active?
        raise "Call #start before #await"
      end

      Metal.kkttyl_await(
        kkttyl,
        40,
        @on_success,
        @on_failure,
        @on_timeout,
        @on_end
      )
    end

    def active?
      !!@kkttyl
    end

    private

    def kkttyl
      @kkttyl ||= Metal.kkttyl_new(@gather_event_duration_ms)
    end
  end
end
