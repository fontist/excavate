# frozen_string_literal: true

require "zlib"

module Excavate
  module Extractors
    class GzipExtractor < Extractor
      def extract(target)
        basename = File.basename(@archive, ".*")
        output_path = File.join(target, basename)

        Zlib::GzipReader.open(@archive) do |gz|
          File.write(output_path, gz.read, mode: "wb")
        end
      end
    end
  end
end
