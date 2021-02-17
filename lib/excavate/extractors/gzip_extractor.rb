module Excavate
  module Extractors
    class GzipExtractor < Extractor
      def extract(target)
        Zlib::GzipReader.open(@archive) do |gz|
          basename = File.basename(@archive, ".*")
          path = File.join(target, basename)
          File.write(path, gz.read, mode: "wb")
        end
      end
    end
  end
end
