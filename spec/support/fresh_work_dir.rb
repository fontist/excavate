RSpec.shared_context "fresh work dir" do
  around do |example|
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        @temp_dir = dir

        example.run

        @temp_dir = nil
      end
    end
  end
end
