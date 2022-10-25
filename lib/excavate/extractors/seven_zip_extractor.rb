require "ffi-libarchive-binary"

module Excavate
  module Extractors
    class SevenZipExtractor < Extractor
      def extract(target)
        Dir.chdir(target) do
          extract_with_libarchive
        end
      end

      def extract_with_libarchive
        flags = ::Archive::EXTRACT_PERM
        reader = ::Archive::Reader.open_filename(@archive)

        reader.each_entry do |entry|
          reader.extract(entry, flags.to_i)
        end

        reader.close
      end
    end
  end
end
