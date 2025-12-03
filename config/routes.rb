Rails.application.routes.draw do
  get "dashboard/top"
  devise_for :users, controllers: {
    registrations: "users/registrations", # 新規登録画面
    sessions: "users/sessions", # ログイン画面
    passwords: "users/passwords" # パスワード再設定リクエスト画面
  }

  devise_scope :user do
    get "/users/sign_out" => "devise/sessions#destroy"
  end

  # ログイン時のルート
  authenticated :user do
    root to: "dashboard#top", as: :authenticated_root
  end
  # 非ログイン時のルート
  unauthenticated do
    root to: "static_pages#top", as: :unauthenticated_root
  end

  # 非ログイン時のルート
  namespace :account do
    get "profiles/show"
    get "profiles/edit"
    get "profiles/update"
    resource :profile, only: [:show, :edit, :update]
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
