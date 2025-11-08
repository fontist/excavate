require "ffi-libarchive-binary"

module Excavate
  module Extractors
    # Extractor for XZ compressed archives (both .xz and .tar.xz formats)
    #
    # This extractor handles:
    # - Pure XZ compressed files (.xz)
    # - Compound TAR+XZ archives (.tar.xz)
    #
    # Uses libarchive through ffi-libarchive-binary for extraction,
    # which provides native XZ decompression support.
    #
    # @example Extract a .tar.xz file
    #   extractor = XzExtractor.new("archive.tar.xz")
    #   extractor.extract("/target/directory")
    #
    # @example Extract a pure .xz file
    #   extractor = XzExtractor.new("file.xz")
    #   extractor.extract("/target/directory")
    class XzExtractor < Extractor
      # Extract the XZ archive to the specified target directory
      #
      # @param target [String] the directory path where files should be extracted
      # @return [void]
      #
      # @raise [StandardError] if extraction fails
      def extract(target)
        extract_with_libarchive(target)
      end

      private

      # Perform extraction using libarchive
      #
      # This method uses libarchive's reader API to:
      # 1. Open the XZ archive
      # 2. Iterate through all entries
      # 3. Extract each entry with appropriate permissions
      # 4. Close the reader
      #
      # @param target [String] the target directory for extraction
      # @return [void]
      def extract_with_libarchive(target)
        flags = ::Archive::EXTRACT_PERM
        reader = ::Archive::Reader.open_filename(@archive)

        Dir.chdir(target) do
          reader.each_entry do |entry|
            reader.extract(entry, flags.to_i)
          end
        end

        reader.close
      end
    end
  end
end
