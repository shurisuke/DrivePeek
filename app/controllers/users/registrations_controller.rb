class Users::RegistrationsController < Devise::RegistrationsController
  # Deviseの時だけname属性を許可する
  before_action :configure_permitted_parameters

  # サインアップ後のリダイレクト先をプラン作成エントリー画面に変更
  def after_sign_up_path_for(resource)
    new_plan_path
  end

  protected

  # 新規登録・アカウント更新でname属性を許可する
  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :name ])
    devise_parameter_sanitizer.permit(:account_update, keys: [ :name ])
  end
end
