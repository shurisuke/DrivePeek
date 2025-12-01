class Users::SessionsController < Devise::SessionsController
  # ログイン後のリダイレクト先をトップページに変更
  def after_sign_in_path_for(resource)
    root_path
  end

  # ログアウト後のリダイレクト先をログイン画面に変更
  def after_sign_out_path_for(resource_or_scope)
    new_user_session_path
  end
end
