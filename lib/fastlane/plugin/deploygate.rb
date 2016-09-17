require "fastlane/plugin/deploygate/version"

module Fastlane
  module Deploygate
    def self.all_classes
      Dir[File.expand_path('*/{actions}/*.rb', File.dirname(__FILE__))]
    end
  end
end

Fastlane::Deploygate.all_classes.each do |current|
  require current
end
