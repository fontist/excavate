RSpec.shared_context "fresh work dir" do
  around do |example|
    # Create temp directory without auto-cleanup to avoid Windows file
    # locking issues - the OS will clean up temp directories eventually
    dir = Dir.mktmpdir
    Dir.chdir(dir) do
      @temp_dir = dir

      example.run

      @temp_dir = nil
    end
  rescue Errno::EACCES, Errno::ENOTEMPTY
    # Ignore cleanup errors on Windows - files may be temporarily locked
    # The OS will eventually clean up the temp directory
  ensure
    # Attempt cleanup but don't fail if it doesn't work
    begin
      FileUtils.rm_rf(dir) if dir && Dir.exist?(dir)
    rescue Errno::EACCES, Errno::ENOTEMPTY
      # Silently ignore Windows file locking errors during cleanup
    end
  end
end
