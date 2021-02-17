require_relative "../lib/deep_extract"

RSpec.configure do |config|
  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!
end
