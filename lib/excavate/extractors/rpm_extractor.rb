require "arr-pm"

H_MAGIC = "\x8e\xad\xe8\x01\x00\x00\x00\x00".force_encoding("BINARY")

# fix for Ruby 3.0
unless RPM::File::Header::HEADER_MAGIC == H_MAGIC
  RPM::File::Header.send(:remove_const, "HEADER_MAGIC")
  RPM::File::Header.const_set(:HEADER_MAGIC, H_MAGIC)
end

module Excavate
  module Extractors
    class RpmExtractor < Extractor
      def extract(target)
        File.open(@archive, "rb") do |file|
          rpm = RPM::File.new(file)
          content = rpm.payload.read
          path = target_path(@archive, rpm.tags, target)

          File.write(path, content, mode: "wb")
        end
      end

      private

      def target_path(archive, tags, dir)
        archive_format = tags[:payloadformat]
        compression_format = tags[:payloadcompressor] == "gzip" ? "gz" : tags[:payloadcompressor]
        basename = File.basename(archive, ".*")
        filename = "#{basename}.#{archive_format}.#{compression_format}"
        File.join(dir, filename)
      end
    end
  end
end
