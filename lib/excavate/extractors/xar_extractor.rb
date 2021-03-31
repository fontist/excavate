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
        payload_path = File.join(target, "Payload")
        return unless File.exist?(payload_path)

        FileUtils.mv(payload_path, "#{payload_path}.cpio.gz")
      end
    end
  end
end
