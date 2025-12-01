Rails.application.routes.draw do
  devise_for :users, controllers: {
    registrations: "users/registrations", # 新規登録画面
    sessions: "users/sessions", # ログイン画面
    passwords: "users/passwords" # パスワード再設定リクエスト画面
  }

  root to: "static_pages#top"
  get "up" => "rails/health#show", as: :rails_health_check
end
