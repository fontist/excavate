# frozen_string_literal: true

require "omnizip"
require "zlib"

module Excavate
  module Extractors
    # Extractor for XZ compressed archives (both .xz and .tar.xz formats)
    #
    # This extractor handles:
    # - Pure XZ compressed files (.xz)
    # - Compound TAR+XZ archives (.tar.xz)
    #
    # Uses Omnizip for XZ decompression.
    class XzExtractor < Extractor
      def extract(target)
        if tar_xz?
          extract_tar_xz(target)
        else
          extract_pure_xz(target)
        end
      end

      private

      def tar_xz?
        @archive.end_with?(".tar.xz", ".txz")
      end

      def extract_tar_xz(target)
        # Decompress XZ to get gzip data
        gzip_data = Omnizip::Formats::Xz.decompress(@archive)
        # Decompress gzip to get tar data
        tar_data = Zlib::GzipReader.new(StringIO.new(gzip_data)).read

        # Write tar file and extract
        temp_tar = File.join(target, ".temp_#{Time.now.to_i}_#{rand(1000)}.tar")
        File.binwrite(temp_tar, tar_data)

        TarExtractor.new(temp_tar).extract(target)
      ensure
        File.delete(temp_tar) if temp_tar && File.exist?(temp_tar)
      end

      def extract_pure_xz(target)
        # Decompress XZ
        data = Omnizip::Formats::Xz.decompress(@archive)
        basename = File.basename(@archive, ".*")
        output_path = File.join(target, basename)
        File.binwrite(output_path, data)
      end
    end
  end
end
