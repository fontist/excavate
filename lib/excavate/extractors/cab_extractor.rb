require "libmspack"

module Excavate
  module Extractors
    class CabExtractor < Extractor
      def extract(target)
        open_cab(@archive) do |decompressor, cab|
          file = cab.files

          while file
            path = File.join(target, file.filename)
            decompressor.extract(file, path)
            file = file.next
          end
        end
      end

      private

      def open_cab(archive)
        decompressor = LibMsPack::CabDecompressor.new
        cab = Utils.silence_stream($stderr) do
          decompressor.search(archive)
        end

        yield decompressor, cab

        decompressor.close(cab)
        decompressor.destroy
      end
    end
  end
end
