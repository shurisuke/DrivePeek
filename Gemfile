source "https://rubygems.org"

ruby "3.2.2"

# Rails本体
gem "rails", "~> 8.1.1"

# アセットパイプライン
gem "propshaft"

# データベース
gem "pg", "~> 1.1"

# Webサーバー
gem "puma", ">= 5.0"

# JavaScript管理
gem "importmap-rails"

# Hotwire
gem "turbo-rails"
gem "stimulus-rails"

# CSS管理(Bootstrap用)
gem "cssbundling-rails"

# JSON API
gem "jbuilder"

# タイムゾーン
gem "tzinfo-data", platforms: %i[ windows jruby ]

# キャッシュ・ジョブ・ケーブル
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"

# 起動高速化
gem "bootsnap", require: false

# デプロイ
gem "kamal", require: false
gem "thruster", require: false

# 画像処理
gem "image_processing", "~> 1.2"

# フォーム支援
gem "simple_form"

# 認証機能
gem "devise"

# SNS認証（OAuth）
gem "omniauth"
gem "omniauth-twitter2"  # X (Twitter) OAuth 2.0
gem "omniauth-line"      # LINE Login
gem "omniauth-rails_csrf_protection"  # CSRF対策

# Bootstrap 5
gem "bootstrap", "~> 5.3.8"

# リスト順序管理
gem "acts_as_list"

# ページネーション
gem "kaminari"

# AI API (OpenAI)
gem "ruby-openai"

# Ruby の SSL 接続を安定化させる
gem "openssl"

group :development, :test do
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"
  gem "bundler-audit", require: false
  gem "brakeman", require: false
  gem "rubocop-rails-omakase", require: false
  gem "dotenv-rails"
end

group :development do
  gem "web-console"
  gem "annotate"
end

group :test do
  gem "capybara"
  gem "selenium-webdriver"
end
