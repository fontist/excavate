require "rubygems/package"

module Excavate
  module Extractors
    class TarExtractor < Extractor
      def extract(target)
        File.open(@archive, "rb") do |archive_file|
          Gem::Package::TarReader.new(archive_file) do |tar|
            tar.each do |tarfile|
              save_tar_file(tarfile, target)
            end
          end
        end
      end

      private

      def save_tar_file(file, dir)
        path = File.join(dir, file.full_name)

        if file.directory?
          FileUtils.mkdir_p(path)
        else
          File.write(path, file.read, mode: "wb")
        end
      end
    end
  end
end
