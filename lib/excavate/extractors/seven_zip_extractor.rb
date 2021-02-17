require "seven_zip_ruby"

module Excavate
  module Extractors
    class SevenZipExtractor < Extractor
      def extract(target)
        File.open(@archive, "rb") do |file|
          SevenZipRuby::Reader.extract_all(file, target)
        end
      end
    end
  end
end
