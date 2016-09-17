# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'fastlane/plugin/deploygate/version'

Gem::Specification.new do |spec|
  spec.name          = 'fastlane-plugin-deploygate'
  spec.version       = Fastlane::Plugin::Deploygate::VERSION
  spec.authors       = ['Tomoki YAMASHITA']
  spec.email         = ['tomorrowkey@gmail.com']

  spec.summary       = %q{A fastlane plugin for uploading apk file/ipa file to Deploygate.}
  spec.description   = %q{A fastlane plugin for uploading apk file/ipa file to Deploygate.}
  spec.homepage      = 'https://github.com/tomorrowkey/fastlane-plugin-deploygate'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.12'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'pry', '~> 0.10'
end
