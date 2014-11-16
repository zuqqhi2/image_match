# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'image_match/version'

Gem::Specification.new do |spec|
  spec.name          = "image_match"
  spec.version       = ImageMatch::VERSION
  spec.authors       = ["Hidetomo Suzuki"]
  spec.email         = ["zuqqhi2@gmail.com"]
  spec.summary       = %q{Check web page or widget design with image file automatically}
  spec.description   = %q{1.Make page or widget image file. 2.Get current page or widget image on the web. 3.Compare them with this gem.}
  spec.homepage      = "https://github.com/zuqqhi2/image_diff"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec"
  
  spec.add_dependency "ruby-opencv", "~> 0.0.13"
end
