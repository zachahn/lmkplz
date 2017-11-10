module Lmkplz
  class Fine
    attr_reader :callbacker

    def initialize(*paths, &block)
      paths.each { |path| interface.add(path) }
      interface.on_success(&block)
    end

    def start
      interface.start
      the_loop

      nil
    end

    def pause
      if @the_loop.nil?
        return
      end

      the_loop.kill
      @the_loop = nil
    end

    private

    def the_loop
      @the_loop ||= Thread.new do
        loop do
          interface.await
        end
      end
    end

    def interface
      @interface ||= K.new
    end
  end
end
