
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "k8s/ruby/version"

Gem::Specification.new do |spec|
  spec.name          = "k8s-ruby"
  spec.version       = K8s::Ruby::VERSION
  spec.authors       = ["rdx.net", "Kontena, Inc."]
  spec.email         = ["firstname.lastname@rdx.net"]
  spec.license       = "Apache-2.0"

  spec.summary       = "Kubernetes client library for Ruby"
  spec.homepage      = "https://github.com/k8s-ruby/k8s-ruby"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "bin"
  spec.executables   = []
  spec.require_paths = ["lib"]
  spec.required_ruby_version = '> 2.4'

  spec.add_runtime_dependency "excon", "~> 0.76"
  spec.add_runtime_dependency "dry-struct", "~> 1.3.0"
  spec.add_runtime_dependency "dry-types", "~> 1.4.0"
  spec.add_runtime_dependency "recursive-open-struct", "~> 1.1.2"
  spec.add_runtime_dependency 'hashdiff', '~> 1.0.1'
  spec.add_runtime_dependency 'jsonpath', '~> 1.0.5'
  spec.add_runtime_dependency 'yajl-ruby', '~> 1.4.1'
  spec.add_runtime_dependency "yaml-safe_load_stream", "~> 0.1.1"

  spec.add_development_dependency "bundler", ">= 1.17", "< 3.0"
  spec.add_development_dependency "rake", ">= 13.0.1"
  spec.add_development_dependency "rspec", "~> 3.9"
  spec.add_development_dependency "webmock", "~> 3.9.1"
  spec.add_development_dependency "rubocop", "~> 0.91"
  spec.add_development_dependency "byebug", "~> 11.1"
end
