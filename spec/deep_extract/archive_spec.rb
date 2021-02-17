RSpec.describe DeepExtract::Archive do
  let(:archive) { File.expand_path("../examples/archives/fonts.zip", __dir__) }

  describe "#files" do
    it "yields" do
      expect { |b| described_class.new(archive).files(&b) }.to yield_control
    end

    it "yields files contained in archive" do
      Array.new.tap do |files|
        described_class.new(archive).files do |f|
          files << f
        end

        expect(files).to include(include("Marlett.ttf"))
      end
    end
  end
end
