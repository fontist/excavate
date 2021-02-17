# frozen_string_literal: true

require_relative "deep_extract/version"
require_relative "deep_extract/archive"
require_relative "deep_extract/extractors"

module DeepExtract
  class Error < StandardError; end
end
