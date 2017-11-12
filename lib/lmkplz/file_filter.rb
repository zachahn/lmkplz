module Lmkplz
  class FileFilter
    def initialize(only: nil, except: nil)
      @matcher =
        if only && except
          raise "`only` and `except` params are mutually exclusive"
        elsif only
          -> (path) { path =~ only }
        elsif except
          -> (path) { path !~ except }
        else
          -> (_path) { true }
        end
    end

    def call(modified_raw, created_raw, removed_raw)
      paths =
        [modified_raw, created_raw, removed_raw]
          .map(&method(:match_or_empty))
          .map(&method(:empty_to_nil))

      if paths.none?
        return
      end

      yield(*paths)
    end

    private

    def match_or_empty(path)
      if @matcher.call(path)
        path
      else
        ""
      end
    end

    def empty_to_nil(path)
      if path == ""
        nil
      else
        path
      end
    end
  end
end
