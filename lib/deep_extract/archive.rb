module DeepExtract
  class Archive
    def initialize(path)
      @path = path
    end

    def files
      Dir.mktmpdir do |target|
        Extractors::ZipExtractor.new(@path).extract(target)

        Dir.glob(File.join(target, "**", "*")).each do |file|
          yield file
        end
      end
    end
  end
end
