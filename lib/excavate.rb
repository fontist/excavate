# frozen_string_literal: true

require_relative "excavate/version"
require_relative "excavate/extractors"
require_relative "excavate/archive"
require_relative "excavate/file_magic"
require_relative "excavate/utils"

module Excavate
  class Error < StandardError; end

  class TargetExistsError < Error; end

  class TargetNotEmptyError < Error; end

  class TargetNotFoundError < Error; end

  class UnknownArchiveError < Error; end
end
