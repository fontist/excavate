require "excavate/cli"

RSpec.describe Excavate::CLI do
  describe "#extract" do
    around do |example|
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          example.run
        end
      end
    end

    around do |example|
      Excavate::Utils.silence_stream(STDOUT) do
        example.run
      end
    end

    let(:command) { described_class.start(args) }
    let(:args) { [spec_root.join("examples/archives/fonts.cab").to_s] }

    context "no command passed" do
      it "extracts anyway" do
        command
        expect(Dir.exist?("fonts")).to be true
      end

      it "prints target path" do
        expect { command }.to output("Successfully extracted to fonts/\n").to_stdout
      end
    end

    context "relative path" do
      let(:args) { ["fonts.cab"] }

      before { FileUtils.cp(spec_root.join("examples/archives/fonts.cab"), ".") }

      it "extracts anyway" do
        command
        expect(Dir.exist?("fonts")).to be true
      end
    end

    context "target exists" do
      before { FileUtils.mkdir("fonts") }

      it "returns error code 2" do
        expect(command).to be 2
      end

      it "prints error message" do
        expect { command }.to output("Target directory `fonts` already exists.\n").to_stdout
      end
    end
  end

  def spec_root
    Pathname.new(File.expand_path("..", __dir__))
  end
end
