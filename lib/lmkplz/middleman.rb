module Lmkplz
  module Kkttyl
    def self.path
      if $USE_DEBUG
        debug_path
      else
        release_path
      end
    end

    def self.release_path
      "ext/kkttyl/target/release/libkkttyl.#{FFI::Platform::LIBSUFFIX}"
    end

    def self.debug_path
      "ext/kkttyl/target/debug/libkkttyl.#{FFI::Platform::LIBSUFFIX}"
    end
  end

  module Middleman
    extend FFI::Library

    ffi_lib Kkttyl.path

    callback :success_callback, %i[string string string], :void
    callback :failure_callback, %i[string], :void
    callback :end_callback, [], :void

    attach_function :cwatch_new, %i[uint64], :pointer
    attach_function :cwatch_add, %i[pointer string], :void
    attach_function :cwatch_await, \
      %i[pointer success_callback failure_callback end_callback], :pointer
  end
end
