Rails.application.routes.draw do
  # ========================================
  # 開発環境専用
  # ========================================
  mount LetterOpenerWeb::Engine, at: "/letter_opener" if Rails.env.development?

  # ========================================
  # Devise（認証）
  # ========================================
  devise_for :users, controllers: {
    registrations: "users/registrations",
    sessions: "users/sessions",
    passwords: "users/passwords",
    confirmations: "users/confirmations",
    omniauth_callbacks: "users/omniauth_callbacks"
  }

  scope :users, as: :users do
    delete "auth/unlink/:provider", to: "users/omniauth_registrations#unlink", as: :omniauth_unlink
  end

  devise_scope :user do
    get "/users/sign_out", to: "devise/sessions#destroy"
  end

  # ========================================
  # ルート
  # ========================================
  authenticated :user do
    root to: "plans#new", as: :authenticated_root
  end

  unauthenticated do
    root to: "static_pages#top", as: :unauthenticated_root
  end

  # ========================================
  # 設定
  # ========================================
  resource :settings, only: %i[show update] do
    get :profile
    patch :profile, action: :update_profile
    get :email
    get :password
    get :sns
    get :account
    get :visibility
  end

  # ========================================
  # プラン関連
  # ========================================
  namespace :plans do
    resources :mine, only: %i[index]
  end

  resources :plans, only: %i[show new create edit update destroy] do
    resources :plan_spots, only: %i[destroy]
  end

  # ========================================
  # 提案機能（AIアシスタント）
  # ========================================
  resources :suggestion_logs, only: [] do
    delete :destroy_all, on: :collection
  end

  resource :suggestions, only: [] do
    post :suggest
    post :finish
  end

  # ========================================
  # スポット関連
  # ========================================
  resources :spots, only: %i[show] do
    resources :comments, only: %i[create destroy], controller: "spot_comments"
    resource :genres, only: %i[show], controller: "spot_genres"
  end

  # ========================================
  # コミュニティ・お気に入り
  # ========================================
  get "community", to: "community#index"
  get "favorites", to: "favorites#index"

  resources :favorite_spots, only: %i[create destroy]
  resources :favorite_plans, only: %i[create destroy]

  # ========================================
  # InfoWindow
  # ========================================
  resource :infowindow, only: %i[show create]

  # ========================================
  # API（JSON）
  # ========================================
  namespace :api do
    resources :popular_spots, only: %i[index]

    resource :start_point, only: %i[update]
    resource :goal_point, only: %i[update]

    resources :plan_spots, only: %i[create update] do
      collection do
        patch :reorder, to: "plan_spot_reorders#update"
        post :adopt, to: "plan_spot_adoptions#create"
      end
    end
  end

  # ========================================
  # 静的ページ
  # ========================================
  get "guide", to: "static_pages#guide", as: :guide
  get "terms", to: "static_pages#terms", as: :terms
  get "privacy", to: "static_pages#privacy", as: :privacy

  # ========================================
  # お問い合わせ
  # ========================================
  resources :contacts, only: %i[new create]

  # ========================================
  # ヘルスチェック
  # ========================================
  get "up", to: "rails/health#show", as: :rails_health_check
end
