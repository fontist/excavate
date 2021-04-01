module Excavate
  class Archive
    TYPES = { "cab" => Extractors::CabExtractor,
              "cpio" => Extractors::CpioExtractor,
              "exe" => Extractors::SevenZipExtractor,
              "gz" => Extractors::GzipExtractor,
              "msi" => Extractors::OleExtractor,
              "rpm" => Extractors::RpmExtractor,
              "tar" => Extractors::TarExtractor,
              "zip" => Extractors::ZipExtractor }.freeze

    def initialize(archive)
      @archive = archive
    end

    def files(recursive_packages: false)
      target = Dir.mktmpdir
      extract(target, recursive_packages: recursive_packages)

      all_files_in(target).map do |file|
        yield file
      end
    ensure
      FileUtils.rm_rf(target)
    end

    def extract(target = nil, recursive_packages: false)
      source = File.expand_path(@archive)
      target ||= default_target(source)
      raise(TargetNotEmptyError, "Target directory `#{File.basename(target)}` is not empty.") unless Dir.empty?(target)

      if recursive_packages
        extract_recursively(source, target)
      else
        extract_once(source, target)
      end

      target
    end

    private

    def default_target(source)
      target = File.expand_path(File.basename(source, ".*"))
      raise(TargetExistsError, "Target directory `#{File.basename(target)}` already exists.") if File.exist?(target)

      FileUtils.mkdir(target)

      target
    end

    def extract_recursively(archive, target)
      extract_once(archive, target)

      all_files_in(target).each do |file|
        next unless archive?(file)

        extract_and_replace(file)
      end
    end

    def extract_once(archive, target)
      extension = normalized_extension(archive)
      extractor_class = TYPES[extension]
      raise(UnknownArchiveError, "Could not unarchive `#{archive}`.") unless extractor_class

      extractor_class.new(archive).extract(target)
    rescue StandardError => e
      raise unless extension == "exe" && e.message.start_with?("Invalid file format")

      Extractors::CabExtractor.new(archive).extract(target)
    end

    def extract_and_replace(archive)
      target = Dir.mktmpdir
      extract_recursively(archive, target)

      FileUtils.rm(archive)
      FileUtils.mv(target, archive)
    rescue FFI::NullPointerError => e
      FileUtils.rmdir(target)
      raise unless normalized_extension(archive) == "exe" &&
        e.message.start_with?("invalid memory read at address=0x0000000000000000")
    end

    def normalized_extension(file)
      fetch_extension(file).downcase
    end

    def fetch_extension(file)
      File.extname(filename(file)).sub(/^\./, "")
    end

    def filename(file)
      if file.respond_to?(:original_filename)
        file.original_filename
      else
        File.basename(file)
      end
    end

    def all_files_in(dir)
      Dir.glob(File.join(dir, "**", "*"))
    end

    def archive?(file)
      return false unless File.file?(file)

      ext = normalized_extension(file)
      TYPES.key?(ext)
    end
  end
end
