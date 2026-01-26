class Users::SessionsController < Devise::SessionsController
  # ログイン時に自動でremember_meを有効化
  before_action :configure_sign_in_params, only: [ :create ]

  # ログイン後のリダイレクト先をプラン作成エントリー画面に変更
  def after_sign_in_path_for(resource)
    new_plan_path
  end

  # ログアウト後のリダイレクト先をログイン前トップページへ変更
  def after_sign_out_path_for(resource_or_scope)
    unauthenticated_root_path
  end

  private

  # 常にremember_meを有効にする
  def configure_sign_in_params
    params[:user] ||= {}
    params[:user][:remember_me] = "1"
  end
end
