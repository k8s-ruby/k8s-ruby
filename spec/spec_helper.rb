require "bundler/setup"
require 'webmock/rspec'
require 'byebug'
require 'pty'

require "k8s-ruby"

require_relative 'helpers/fixture_helpers'

if ENV['DEBUG']
  K8s::Logging.debug!
  K8s::Transport.verbose!
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  # Run only specific tests with fdescribe, fcontext and fit
  config.filter_run_when_matching :focus

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before(:suite) do
    RSpec::Matchers.define :have_file_content do |expected_content|
      match do |file_path|
        File.read(file_path) == expected_content
      end
    end
  end
end
