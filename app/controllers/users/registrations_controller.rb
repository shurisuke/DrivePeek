class Users::RegistrationsController < Devise::RegistrationsController
  before_action :configure_permitted_parameters

  # 情報更新処理（失敗時のリダイレクト先をカスタマイズ）
  def update
    self.resource = resource_class.to_adapter.get!(send(:"current_#{resource_name}").to_key)
    prev_unconfirmed_email = resource.unconfirmed_email if resource.respond_to?(:unconfirmed_email)

    resource_updated = update_resource(resource, account_update_params)

    if resource_updated
      # 成功時
      bypass_sign_in resource, scope: resource_name if sign_in_after_change_password?

      # メール変更で確認待ちの場合は同じ画面に留まる
      if params[:section] == "email" && resource.unconfirmed_email.present?
        redirect_to edit_user_registration_path(section: :email), notice: update_success_message
      else
        redirect_to after_update_path_for(resource), notice: update_success_message
      end
    else
      # 失敗時: 同じセクションの画面に戻る
      clean_up_passwords resource
      set_minimum_password_length
      redirect_to edit_user_registration_path(section: params[:section]), alert: resource.errors.full_messages.first
    end
  end

  # サインアップ後のリダイレクト先をプロフィール設定画面に変更
  def after_sign_up_path_for(resource)
    users_profile_setup_path(from: "signup")
  end

  # 情報更新後のリダイレクト先を設定画面に変更
  def after_update_path_for(resource)
    settings_path
  end

  protected

  # 新規登録・アカウント更新で追加属性を許可する
  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :age_group, :gender, :residence ])
    devise_parameter_sanitizer.permit(:account_update, keys: [ :age_group, :gender, :residence, :status ])
  end

  # プロフィール変更時はパスワード不要にする
  def update_resource(resource, params)
    # メールアドレス・パスワード変更時は現在のパスワードを要求
    if params[:email].present? || params[:password].present?
      super
    else
      # プロフィール変更のみの場合はパスワード不要
      resource.update(params.except(:current_password))
    end
  end

  private

  def sign_in_after_change_password?
    Devise.sign_in_after_change_password
  end

  def update_success_message
    case params[:section]
    when "email"
      if resource.unconfirmed_email.present?
        "確認メールを送信しました。メール内のリンクをクリックして変更を確定してください。"
      else
        "メールアドレスを変更しました"
      end
    when "password"
      "パスワードを変更しました"
    else
      "プロフィールを更新しました"
    end
  end
end
