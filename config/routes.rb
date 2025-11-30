Rails.application.routes.draw do
  get "static_pages/top"
  # 標準のヘルスチェック用エンドポイント
  get "up" => "rails/health#show", as: :rails_health_check

  root to: 'static_pages#top'
end
