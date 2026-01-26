# frozen_string_literal: true

require "spec_helper"
ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"

abort("The Rails environment is running in production mode!") if Rails.env.production?

require "rspec/rails"
require "webmock/rspec"

# サポートファイル読み込み
Rails.root.glob("spec/support/**/*.rb").sort_by(&:to_s).each { |f| require f }

# 外部HTTPリクエストを無効化（localhost除く）
WebMock.disable_net_connect!(allow_localhost: true)

begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end

RSpec.configure do |config|
  # FactoryBot
  config.include FactoryBot::Syntax::Methods

  # Devise
  config.include Devise::Test::ControllerHelpers, type: :controller
  config.include Devise::Test::IntegrationHelpers, type: :request
  config.include Devise::Test::IntegrationHelpers, type: :system

  # DatabaseCleaner
  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
    # Deviseのルーティングを確実にロード
    Rails.application.reload_routes!
  end

  config.around(:each) do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end

  # ActionMailer: テスト前に配信キューをクリア
  config.before(:each) do
    ActionMailer::Base.deliveries.clear
  end

  # フィクスチャ無効化（FactoryBot使用）
  config.use_transactional_fixtures = false

  # ファイル位置から型を推論
  config.infer_spec_type_from_file_location!

  # Railsのバックトレースをフィルタリング
  config.filter_rails_from_backtrace!
end

# Shoulda Matchers
Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end
