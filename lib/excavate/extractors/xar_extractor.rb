require "ffi-libarchive-binary"

module Excavate
  module Extractors
    class XarExtractor < Extractor
      def extract(target)
        Dir.chdir(target) do
          extract_with_libarchive
          rename_payload(target)
        end
      end

      private

      def extract_with_libarchive
        flags = ::Archive::EXTRACT_PERM
        reader = ::Archive::Reader.open_filename(@archive)

        reader.each_entry do |entry|
          reader.extract(entry, flags.to_i)
        end

        reader.close
      end

      def rename_payload(target)
        Dir.glob(File.join(target, "**", "Payload")).each do |file|
          next unless File.file?(file)

          FileUtils.mv(file, "#{file}.cpio.gz")
        end
      end
    end
  end
end
