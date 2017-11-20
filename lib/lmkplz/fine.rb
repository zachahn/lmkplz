module Lmkplz
  class Fine
    attr_reader :callbacker

    def initialize(*paths, only: nil, except: nil, &block)
      @block = block
      @file_filter = FileFilter.new(only: only, except: except)
      paths.each { |path| interface.add(path) }

      interface.on_success do |m, c, r|
        @file_filter.call(m, c, r) do |mm, cc, rr|
          @block.call(mm, cc, rr)
        end
      end
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
      @interface ||= Once.new
    end
  end
end
