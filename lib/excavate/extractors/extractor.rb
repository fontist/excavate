module Excavate
  module Extractors
    class Extractor
      def initialize(archive)
        @archive = archive
      end

      def extract(_target)
        raise NotImplementedError.new("You must implement this method")
      end
    end
  end
end
