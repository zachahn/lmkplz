module Lmkplz
  class Encasement
    def initialize
      @callback_mutex = Mutex.new
      @add_paths_mutex = Mutex.new
      @add_paths_queue = []
      @gather_event_duration_ms = 200
      @callbacks = Hash.new { -> {} }
    end

    def self.define_settable_callback(name)
      define_method("on_#{name}") do |&block|
        @callback_mutex.synchronize { @callbacks[name] = block }
      end
    end

    define_settable_callback :success
    define_settable_callback :failure
    define_settable_callback :timeout
    define_settable_callback :end

    def malloc
      kkttyl

      @add_paths_mutex.synchronize do
        while @add_paths_queue.any?
          add(@add_paths_queue.pop)
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
        @add_paths_mutex.synchronize do
          @add_paths_queue.push(dir)
        end
      end
    end

    def await
      if !active?
        raise "Call #malloc before #await"
      end

      callbacks =
        @callback_mutex.synchronize do
          @callbacks.values_at(:success, :failure, :timeout, :end)
        end

      Metal.kkttyl_await(kkttyl, 40, *callbacks)
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
