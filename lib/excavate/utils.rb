module Excavate
  module Utils
    module_function

    def silence_stream(stream)
      old_stream = stream.dup
      stream.reopen(/mswin|mingw/.match?(RbConfig::CONFIG["host_os"]) ? File::NULL : File::NULL)
      stream.sync = true
      yield
    ensure
      stream.reopen(old_stream)
    end
  end
end
