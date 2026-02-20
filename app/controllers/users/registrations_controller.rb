class Users::RegistrationsController < Devise::RegistrationsController
  before_action :configure_permitted_parameters

  # 新規登録画面表示時にリダイレクト先をセッションに保存
  def new
    store_redirect_path
    super
  end

  # /users/edit へのアクセスは設定画面にリダイレクト
  def edit
    redirect_to settings_path
  end

  # メールアドレス変更処理
  def update
    self.resource = resource_class.to_adapter.get!(send(:"current_#{resource_name}").to_key)
    resource_updated = update_resource(resource, account_update_params)

    if resource_updated
      bypass_sign_in resource, scope: resource_name if sign_in_after_change_password?
      redirect_to email_settings_path, notice: email_update_message
    else
      clean_up_passwords resource
      set_minimum_password_length
      redirect_to email_settings_path, alert: resource.errors.full_messages.first
    end
  end

  # サインアップ後のリダイレクト先をプロフィール設定画面に変更
  def after_sign_up_path_for(resource)
    profile_settings_path(from: "signup")
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

  # redirect_toパラメータをセッションに保存
  def store_redirect_path
    path = params[:redirect_to]
    session[:redirect_after_auth] = path if path.present? && path.start_with?("/")
  end

  def sign_in_after_change_password?
    Devise.sign_in_after_change_password
  end

  def email_update_message
    if resource.unconfirmed_email.present?
      "確認メールを送信しました。メール内のリンクをクリックして変更を確定してください。"
    else
      "メールアドレスを変更しました"
    end
  end
end
