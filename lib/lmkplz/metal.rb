module Lmkplz
  module External
    def self.path
      path =
        if defined?($USE_DEBUG_KKTTYL) && $USE_DEBUG_KKTTYL
          warn "🐝  Using debug build of kkttyl"
          debug_path
        else
          release_path
        end

      File.expand_path(path, File.join(__dir__, "../.."))
    end

    def self.release_path
      "ext/kkttyl/target/release/libkkttyl.#{FFI::Platform::LIBSUFFIX}"
    end

    def self.debug_path
      "ext/kkttyl/target/debug/libkkttyl.#{FFI::Platform::LIBSUFFIX}"
    end
  end

  module Metal
    extend FFI::Library

    ffi_lib External.path

    callback :success_callback, %i[string string string], :void
    callback :failure_callback, %i[], :void
    callback :timeout_callback, %i[], :void
    callback :end_callback, %i[], :void

    attach_function :kkttyl_new, %i[uint64], :pointer
    attach_function :kkttyl_free, %i[pointer], :void
    attach_function :kkttyl_add, %i[pointer string], :void
    attach_function :kkttyl_await, \
      %i[
        pointer
        uint64
        success_callback
        failure_callback
        timeout_callback
        end_callback
      ], :void
  end
end
