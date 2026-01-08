class Users::SessionsController < Devise::SessionsController
  # ログイン後のリダイレクト先をプラン作成エントリー画面に変更
  def after_sign_in_path_for(resource)
    new_plan_path
  end

  # ログアウト後のリダイレクト先をログイン前トップページへ変更
  def after_sign_out_path_for(resource_or_scope)
    unauthenticated_root_path
  end
end
