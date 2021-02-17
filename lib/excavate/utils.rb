module Excavate
  module Utils
    module_function

    def silence_stream(stream)
      old_stream = stream.dup
      stream.reopen(RbConfig::CONFIG["host_os"] =~ /mswin|mingw/ ? "NUL:" : "/dev/null") # rubocop:disable Performance/RegexpMatch, Metrics/LineLength
      stream.sync = true
      yield
    ensure
      stream.reopen(old_stream)
    end
  end
end
