Rails.application.routes.draw do
  get "dashboard/top"

  # Devise関連
  devise_for :users, controllers: {
    registrations: "users/registrations", # 新規登録画面
    sessions: "users/sessions",           # ログイン画面
    passwords: "users/passwords"          # パスワード再設定リクエスト画面
  }

  # ログイン時のルート
  authenticated :user do
    root to: "dashboard#top", as: :authenticated_root
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
  resources :plans, only: %i[index create edit update destroy] do
    resource :planbar, only: %i[show]
    resource :start_point, only: %i[update]
    resource :goal_point, only: %i[update]

    resources :plan_spots, only: %i[create destroy] do
      # ✅ タグ（追加/削除）: /plans/:plan_id/plan_spots/:plan_spot_id/tags
      resources :tags, only: %i[create destroy], module: :plan_spots

      collection do
        # スポット順並び替え
        patch :reorder, to: "plan_spots/reorders#update"
      end

      member do
        # 有料道路使用切り替え
        patch :update_toll_used, to: "plan_spots/toll_used#update"

        # メモ更新
        patch :update_memo, to: "plan_spots/memos#update"
      end
    end
  end

  # お気に入りスポット
  resources :like_spots, only: %i[create destroy]

  # ヘルスチェック
  get "up" => "rails/health#show", as: :rails_health_check
end