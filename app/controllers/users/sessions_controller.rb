class Users::SessionsController < Devise::SessionsController
  # ログイン時に自動でremember_meを有効化
  before_action :configure_sign_in_params, only: [ :create ]

  # ログイン画面表示時にリダイレクト先をセッションに保存
  def new
    store_redirect_path
    super
  end

  # ログイン後のリダイレクト先
  def after_sign_in_path_for(resource)
    session.delete(:redirect_after_auth) || new_plan_path
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

  # redirect_toパラメータをセッションに保存
  def store_redirect_path
    path = params[:redirect_to]
    session[:redirect_after_auth] = path if path.present? && path.start_with?("/")
  end
end
