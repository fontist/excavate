# frozen_string_literal: true

require "omnizip"

module Excavate
  module Extractors
    class SevenZipExtractor < Extractor
      def extract(target)
        # Check for embedded 7z in self-extracting archives
        offset = Omnizip::Formats::SevenZip.search_embedded(@archive)

        if offset
          # Self-extracting archive - use offset
          Omnizip::Formats::SevenZip.open(@archive, offset: offset) do |reader|
            reader.extract_all(target)
          end
        else
          # Regular 7z archive
          Omnizip::Formats::SevenZip.open(@archive) do |reader|
            reader.extract_all(target)
          end
        end
      end
    end
  end
end
