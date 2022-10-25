require_relative "cpio/cpio"
require_relative "cpio/cpio_old_format"

module Excavate
  module Extractors
    class CpioExtractor < Extractor
      def extract(target)
        extract_cpio_new_format(target)
      rescue RuntimeError => e
        raise unless e.message.start_with?("Invalid magic")

        extract_cpio_old_format(target)
      end

      private

      def extract_cpio_inner_new(entry, file, target)
        path = File.join(target, entry.name)
        if entry.directory?
          FileUtils.mkdir_p(path)
        else
          FileUtils.mkdir_p(File.dirname(path))
          File.write(path, file.read, mode: "wb")
        end
      end

      def extract_cpio_new_format(target)
        File.open(@archive, "rb") do |archive_file|
          CPIO::ASCIIReader.new(archive_file).each do |entry, file|
            extract_cpio_inner_new(entry, file, target)
          end
        end
      end

      def extract_cpio_inner_old(entry, target)
        path = File.expand_path(entry.filename, target)
        if entry.directory?
          FileUtils.mkdir_p(path)
        else
          FileUtils.mkdir_p(File.dirname(path))
          File.write(path, entry.data, mode: "wb")
        end
      end

      def extract_cpio_old_format(target)
        File.open(@archive, "rb") do |archive_file|
          CPIO::ArchiveReader.new(archive_file).each_entry do |entry|
            extract_cpio_inner_old(entry, target)
          end
        end
      end
    end
  end
end
