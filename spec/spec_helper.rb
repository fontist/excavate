require_relative "../lib/excavate"

Dir["./spec/support/**/*.rb"].sort.each { |file| require file }

RSpec.configure do |config| # rubocop:disable Style/SymbolProc
  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!
end
