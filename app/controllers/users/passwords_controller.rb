# frozen_string_literal: true

class Users::PasswordsController < Devise::PasswordsController
  # 認証済みユーザーでもパスワードリセットフローを利用可能にする
  skip_before_action :require_no_authentication

  protected

  def after_sending_reset_password_instructions_path_for(_resource_name)
    password_settings_path
  end

  def after_resetting_password_path_for(_resource)
    settings_path
  end
end
