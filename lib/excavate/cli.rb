require "thor"

require_relative "../excavate"

module Excavate
  class CLI < Thor
    STATUS_SUCCESS = 0
    STATUS_UNKNOWN_ERROR = 1
    STATUS_TARGET_EXISTS = 2
    STATUS_TARGET_NOT_EMPTY = 3

    def self.exit_on_failure?
      false
    end

    def self.start(given_args = ARGV, config = {})
      args = if all_commands.key?(given_args[0])
               given_args
             else
               given_args.dup.unshift("extract")
             end

      super(args, config)
    end

    desc "extract ARCHIVE", "Extract ARCHIVE to a new directory"
    option :recursive, aliases: :r, type: :boolean, default: false, desc: "Also extract all nested archives."
    def extract(archive)
      target = Excavate::Archive.new(archive).extract(recursive_packages: options[:recursive])
      success("Successfully extracted to #{File.basename(target)}/")
    rescue TargetExistsError => e
      error(e.message, STATUS_TARGET_EXISTS)
    rescue TargetNotEmptyError => e
      error(e.message, STATUS_TARGET_NOT_EMPTY)
    end
    default_task :extract

    private

    def success(message)
      say(message)
      STATUS_SUCCESS
    end

    def error(message, status)
      say(message, :red)
      status
    end
  end
end
