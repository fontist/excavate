require "ffi-libarchive-binary"

module Excavate
  module Extractors
    class XarExtractor < Extractor
      def extract(target)
        Dir.chdir(target) do
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
end
