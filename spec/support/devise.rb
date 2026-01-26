# frozen_string_literal: true

require "devise"

# Devise mappingをテスト用に設定
Warden.test_mode!

RSpec.configure do |config|
  config.include Warden::Test::Helpers

  config.after(:each) do
    Warden.test_reset!
  end
end
