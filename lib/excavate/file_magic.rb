module Excavate
  class FileMagic
    def self.detect(path)
      new(path).detect
    end

    def initialize(path)
      @path = path
    end

    def detect
      beginning = File.read(@path, 8, mode: "rb")
      case beginning
      when "MSCF\x00\x00\x00\x00".force_encoding("BINARY")
        :cab
      else
        case beginning.byteslice(0, 2)
        when "\x1F\x8B".force_encoding("BINARY")
          :gzip
        end
      end
    end
  end
end
