Rails.application.routes.draw do
  # Devise関連
  devise_for :users, controllers: {
    registrations: "users/registrations", # 新規登録画面
    sessions: "users/sessions",           # ログイン画面
    passwords: "users/passwords"          # パスワード再設定リクエスト画面
  }

  # ログイン時のルート
  authenticated :user do
    root to: "plans#new", as: :authenticated_root
  end

  # 非ログイン時のルート
  unauthenticated do
    root to: "static_pages#top", as: :unauthenticated_root
  end

  # ログアウト時のアクション
  devise_scope :user do
    get "/users/sign_out" => "devise/sessions#destroy"
  end

  # マイページ
  namespace :account do
    resource :profile, only: %i[show edit update]
  end

  # プラン
  namespace :plans do
    resources :my_plans, only: %i[index]
  end

  resources :plans, only: %i[index show new create edit update destroy] do
    resource :navibar, only: %i[show]

    # Turbo Stream用（destroyのみ残す）
    resources :plan_spots, only: %i[destroy]
  end

  # API エンドポイント
  namespace :api do
    resources :plans, only: [] do
      resource :preview, only: %i[show], controller: "plans/previews"
      resource :start_point, only: %i[update]
      resource :goal_point, only: %i[update]

      resources :plan_spots, only: %i[create] do
        collection do
          patch :reorder, to: "plan_spots/reorders#update"
        end

        member do
          patch :toll_used, to: "plan_spots/toll_used#update"
          patch :memo, to: "plan_spots/memos#update"
          patch :stay_duration, to: "plan_spots/stay_durations#update"
        end
      end
    end
  end

  # お気に入りスポット
  resources :like_spots, only: %i[create destroy]

  # お気に入りプラン
  resources :like_plans, only: %i[create destroy]

  # ヘルスチェック
  get "up" => "rails/health#show", as: :rails_health_check

  # 静的ページ（利用規約・プライバシーポリシー）
  get "terms" => "static_pages#terms", as: :terms
  get "privacy" => "static_pages#privacy", as: :privacy
end
