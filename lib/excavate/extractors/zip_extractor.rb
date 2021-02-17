require "zip"

module Excavate
  module Extractors
    class ZipExtractor < Extractor
      def extract(target)
        Zip::File.open(@archive) do |zip_file|
          zip_file.each do |entry|
            path = File.join(target, entry.name)
            FileUtils.mkdir_p(File.dirname(path))
            entry.extract(path)
          end
        end
      end
    end
  end
end
