class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  # Deviseの時だけname属性を許可する
  before_action :configure_permitted_parameters, if: :devise_controller?

  # 新規登録後のリダイレクト先設定
  def after_sign_up_path_for(resource)
    new_user_session_path
  end

  protected
  # 新規登録・アカウント更新でname属性を許可する
  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name])
    devise_parameter_sanitizer.permit(:account_update, keys: [:name])
  end
end