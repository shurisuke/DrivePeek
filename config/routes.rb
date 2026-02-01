Rails.application.routes.draw do
  # 開発環境のみ：メール確認用UI
  mount LetterOpenerWeb::Engine, at: "/letter_opener" if Rails.env.development?

  # Devise関連
  devise_for :users, controllers: {
    registrations: "users/registrations",        # 新規登録画面
    sessions: "users/sessions",                  # ログイン画面
    passwords: "users/passwords",                # パスワード再設定リクエスト画面
    confirmations: "users/confirmations",        # メール確認
    omniauth_callbacks: "users/omniauth_callbacks" # SNS認証コールバック
  }

  # ユーザー関連
  scope :users, as: :users do
    # SNS連携解除
    delete "auth/unlink/:provider", to: "users/omniauth_registrations#unlink", as: :omniauth_unlink
  end

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

  # 設定
  resource :settings, only: %i[show update] do
    get :profile
    patch :profile, action: :update_profile
    get :email
    get :password
    get :sns
    get :account
    get :visibility
  end

  # プラン
  namespace :plans do
    resources :mine, only: %i[index]
  end

  resources :plans, only: %i[index show new create edit update destroy] do
    # Turbo Stream用（destroyのみ残す）
    resources :plan_spots, only: %i[destroy]
  end

  # 提案機能（AIアシスタント）
  resources :suggestion_logs, only: [] do
    collection do
      delete :destroy_all
    end
  end

  resource :suggestions, only: [], controller: "suggestions" do
    post :suggest
    post :finish
  end

  # API エンドポイント
  namespace :api do

    # InfoWindow（POST: JS fetch用、GET: Turbo Frame用）
    resource :infowindow, only: %i[show create]

    # スポット関連
    resources :spots, only: [] do
      resource :genres, only: [ :show ], controller: "spots/genres"
    end

    resources :plans, only: [] do
      resource :preview, only: %i[show], controller: "plans/previews"
      resource :start_point, only: %i[update]
      resource :goal_point, only: %i[update]

      resources :plan_spots, only: %i[create] do
        collection do
          patch :reorder, to: "plan_spots/reorders#update"
          post :adopt
        end

        member do
          patch :toll_used, to: "plan_spots/toll_used#update"
          patch :memo, to: "plan_spots/memos#update"
          patch :stay_duration, to: "plan_spots/stay_durations#update"
        end
      end
    end
  end

  # スポット
  resources :spots, only: %i[show] do
    resources :comments, only: %i[create destroy], controller: "spot_comments"
  end

  # お気に入り一覧
  get "favorites" => "favorites#index"

  # お気に入りスポット
  resources :favorite_spots, only: %i[create destroy]

  # お気に入りプラン
  resources :favorite_plans, only: %i[create destroy]

  # ヘルスチェック
  get "up" => "rails/health#show", as: :rails_health_check

  # 静的ページ
  get "guide" => "static_pages#guide", as: :guide
  get "terms" => "static_pages#terms", as: :terms
  get "privacy" => "static_pages#privacy", as: :privacy

  # お問い合わせ
  resources :contacts, only: %i[new create]
end
