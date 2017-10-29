module Lmkplz
  class Notifier
    attr_reader :callbacker

    def initialize(*paths, &block)
      @files = Queue.new

      paths.each { |path| interface.add(path) }
      interface.on_success(&block)

      @logger = Logger.new($stdout)
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
          @logger.info "awaiting"
          begin
            Timeout.timeout(1) do
              interface.await
            end
          rescue Timeout::Error
            @logger.info "lol nvm"
            Thread.pass
          end
          @logger.info "awaited"
        end
      end
    end

    def interface
      @interface ||= Interface.new
    end
  end
end
