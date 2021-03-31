RSpec.describe Excavate::Archive do
  describe "#files" do
    let(:archive) { File.expand_path("../examples/archives/#{archive_example}", __dir__) }

    shared_examples "yields filename" do |filename|
      it "yields files contained in archive" do
        Array.new.tap do |files|
          described_class.new(archive).files do |f|
            files << f
          end

          expect(files).to include(include(filename))
        end
      end
    end

    context "any archive" do
      let(:archive_example) { "fonts.zip" }

      it "yields" do
        expect { |b| described_class.new(archive).files(&b) }.to yield_control
      end
    end

    context "cab" do
      context "cab extension" do
        let(:archive_example) { "fonts.cab" }

        include_examples "yields filename", "Marlett.ttf"
      end

      context "exe extension" do
        let(:archive_example) { "fonts_cab.exe" }

        include_examples "yields filename", "Marlett.ttf"
      end
    end

    context "cpio" do
      context "old format" do
        let(:archive_example) { "fonts_old.cpio" }

        include_examples "yields filename", "Marlett.ttf"
      end

      context "new format" do
        let(:archive_example) { "fonts_new.cpio" }

        include_examples "yields filename", "Marlett.ttf"
      end
    end

    context "gzip" do
      let(:archive_example) { "fonts.tar.gz" }

      include_examples "yields filename", "fonts.tar"
    end

    context "ole" do
      let(:archive_example) { "fonts.msi" }

      include_examples "yields filename", ".cab"
    end

    context "rpm" do
      let(:archive_example) { "fonts.src.rpm" }

      include_examples "yields filename", "fonts.src.cpio.gz"
    end

    context "seven_zip" do
      let(:archive_example) { "fonts_7z.exe" }

      include_examples "yields filename", "Marlett.ttf"
    end

    context "tar" do
      let(:archive_example) { "fonts.tar" }

      include_examples "yields filename", "Marlett.ttf"
    end

    context "xar" do
      let(:archive_example) { "archive.pkg" }

      include_examples "yields filename", "Payload"
    end

    context "zip" do
      let(:archive_example) { "fonts.zip" }

      include_examples "yields filename", "Marlett.ttf"
    end

    context "recursive packages" do
      shared_examples "yields filename recursively" do |filename|
        it "yields files contained in archive" do
          Array.new.tap do |files|
            described_class.new(archive).files(recursive_packages: true) do |f|
              files << f
            end

            expect(files).to include(include(filename))
          end
        end
      end

      context "gzip" do
        let(:archive_example) { "fonts.tar.gz" }

        include_examples "yields filename recursively", "Marlett.ttf"
      end

      context "ole" do
        let(:archive_example) { "fonts.msi" }

        include_examples "yields filename recursively", "Marlett.ttf"
      end

      context "rpm" do
        let(:archive_example) { "fonts.src.rpm" }

        include_examples "yields filename recursively", "Example.txt"
      end

      context "pkg" do
        let(:archive_example) { "archive.pkg" }

        include_examples "yields filename recursively", "file.txt"
      end

      context "failing subarchive" do
        let(:archive_example) { "fonts_failing_subarchive.zip" }

        include_examples "yields filename recursively", "Marlett.ttf"
      end

      context "folder with archive extension" do
        let(:archive_example) { "folder_with_extension.zip" }

        include_examples "yields filename recursively", "file.txt"
      end
    end
  end
end
