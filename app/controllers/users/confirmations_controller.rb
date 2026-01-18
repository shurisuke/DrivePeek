class Users::ConfirmationsController < Devise::ConfirmationsController
  # メール確認後のリダイレクト先を設定画面に変更
  def after_confirmation_path_for(resource_name, resource)
    settings_path
  end
end
