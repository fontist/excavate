require "ole/storage"

module Excavate
  module Extractors
    class OleExtractor < Extractor
      def extract(target)
        do_extract(target)
        rename_archives(target)
      end

      private

      def do_extract(target)
        reset_filename_lookup

        Ole::Storage.open(@archive) do |ole|
          children(ole).each do |file|
            next if ole.file.directory?(file)

            filename = prepare_filename(file)
            path = File.join(target, filename)
            content = ole.file.read(file)
            File.write(path, content, mode: "wb")
          end
        end
      end

      def children(ole)
        ole.dir.entries(".") - [".", ".."]
      end

      def reset_filename_lookup
        @file_lookup = {}
      end

      def prepare_filename(file)
        filename = sanitize_filename(file)

        @file_lookup[filename] ||= 0
        @file_lookup[filename] += 1
        filename += @file_lookup[filename].to_s if @file_lookup[filename] > 1

        filename
      end

      def sanitize_filename(filename)
        filename.strip.tap do |name|
          # NOTE: File.basename doesn't work right with Windows paths on Unix
          # get only the filename, not the whole path
          name.gsub!(/^.*(\\|\/)/, "")

          # Strip out the non-ascii character
          name.gsub!(/[^0-9A-Za-z.\-]/, "_")
        end
      end

      def rename_archives(target)
        Dir.glob(File.join(target, "**", "*")).each do |file|
          FileUtils.mv(file, "#{file}.cab") if cab?(file)
        end
      end

      def cab?(file)
        FileMagic.detect(file) == :cab
      end
    end
  end
end
