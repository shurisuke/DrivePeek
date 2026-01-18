class Users::OmniauthRegistrationsController < ApplicationController
  before_action :authenticate_user!

  # SNS連携解除
  def unlink
    provider = params[:provider]
    identity = current_user.identities.find_by(provider: provider)

    # SNS連携のみのユーザーは解除不可
    if current_user.sns_only_user? && current_user.identities.count == 1
      redirect_to sns_settings_path, alert: "ログイン方法がなくなるため、連携を解除できません"
      return
    end

    if identity&.destroy
      redirect_to sns_settings_path, notice: "SNS連携を解除しました"
    else
      redirect_to sns_settings_path, alert: "連携解除に失敗しました"
    end
  end
end
