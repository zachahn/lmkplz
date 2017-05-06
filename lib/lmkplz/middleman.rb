module Lmkplz
  module Middleman
    extend FFI::Library

    ffi_lib "ext/kkttyl/target/release/libkkttyl.dylib"

    callback :success_callback, [:string, :string], :void
    callback :failure_callback, [:string], :void
    callback :end_callback, [], :void

    attach_function :new_cwatch, [:uint64], :pointer
    attach_function :add_cwatch, [:pointer, :string], :void
    attach_function :watch_cwatch, [:pointer, :success_callback, :failure_callback, :end_callback], :pointer
  end
end
