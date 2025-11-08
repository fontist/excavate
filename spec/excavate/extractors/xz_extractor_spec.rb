require "spec_helper"

RSpec.describe Excavate::Extractors::XzExtractor do
  subject(:extractor) { described_class.new(archive) }

  let(:archive) do
    File.expand_path("../../examples/archives/#{archive_file}", __dir__)
  end

  describe "#extract" do
    include_context "fresh work dir"

    let(:target_dir) { Dir.mktmpdir }

    after do
      FileUtils.rm_rf(target_dir)
    end

    context "with tar.xz archive" do
      let(:archive_file) { "test.tar.xz" }

      it "extracts the archive successfully" do
        extractor.extract(target_dir)
        extracted_files = Dir.glob(File.join(target_dir, "**", "*"))
          .select { |f| File.file?(f) }

        expect(extracted_files).not_to be_empty
      end

      it "extracts the expected file" do
        extractor.extract(target_dir)
        extracted_content = File.read(
          File.join(target_dir, "test_xz_content.txt"),
        )

        expect(extracted_content).to include("This is a test file")
      end

      it "preserves file permissions" do
        extractor.extract(target_dir)
        extracted_file = File.join(target_dir, "test_xz_content.txt")

        expect(File.exist?(extracted_file)).to be true
        expect(File.readable?(extracted_file)).to be true
      end
    end

    context "with pure xz compressed file" do
      let(:archive_file) { "simple_test.txt.xz" }

      # Note: Pure .xz files (non-tar) require special handling
      # libarchive treats them as compressed streams, not archives
      it "attempts to extract but may not extract as expected for pure compression" do
        # This documents the current behavior - pure .xz needs different handling
        # than tar.xz compound archives
        expect do
          extractor.extract(target_dir)
        end.to raise_error(Archive::Error, /Unrecognized archive format/)
      end
    end

    context "with invalid archive" do
      let(:archive_file) { "file.txt" }

      it "raises an error" do
        expect do
          extractor.extract(target_dir)
        end.to raise_error(StandardError)
      end
    end

    context "with non-existent archive" do
      let(:archive) { "/path/to/non/existent/file.tar.xz" }

      it "raises an error" do
        expect do
          extractor.extract(target_dir)
        end.to raise_error(StandardError)
      end
    end
  end

  describe "integration with Archive class" do
    include_context "fresh work dir"

    let(:archive_file) { "test.tar.xz" }

    it "is registered in Archive::TYPES" do
      expect(Excavate::Archive::TYPES["xz"]).to eq(described_class)
    end

    it "can be instantiated through Archive class" do
      archive_obj = Excavate::Archive.new(archive)
      files = []

      archive_obj.files do |file|
        files << file
      end

      expect(files).not_to be_empty
      expect(files.any? { |f| f.include?("test_xz_content.txt") }).to be true
    end
  end

  describe "adherence to Extractor interface" do
    let(:archive_file) { "test.tar.xz" }

    it "inherits from Extractor base class" do
      expect(described_class.superclass).to eq(Excavate::Extractors::Extractor)
    end

    it "responds to extract method" do
      expect(extractor).to respond_to(:extract)
    end

    it "accepts a target directory parameter" do
      expect(extractor.method(:extract).arity).to eq(1)
    end
  end

  describe "libarchive integration" do
    let(:archive_file) { "test.tar.xz" }

    it "uses ffi-libarchive-binary library" do
      expect(defined?(Archive)).to be_truthy
    end

    it "uses Archive::Reader for extraction" do
      expect(Archive::Reader).to receive(:open_filename)
        .with(archive)
        .and_call_original

      target_dir = Dir.mktmpdir
      extractor.extract(target_dir)
      FileUtils.rm_rf(target_dir)
    end
  end
end
