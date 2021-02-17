module Excavate
  class FileMagic
    def self.detect(path)
      new(path).detect
    end

    def initialize(path)
      @path = path
    end

    def detect
      case File.read(@path, 8, mode: "rb")
      when "MSCF\x00\x00\x00\x00".force_encoding("BINARY")
        :cab
      end
    end
  end
end
