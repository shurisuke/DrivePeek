class Users::SessionsController < Devise::SessionsController
  # ログイン後のリダイレクト先をログイン後トップページに変更
  def after_sign_in_path_for(resource)
    authenticated_root_path
  end

  # ログアウト後のリダイレクト先をログイン前トップページへ変更
  def after_sign_out_path_for(resource_or_scope)
    unauthenticated_root_path
  end
end
