class SettingsController < ApplicationController
  before_action :authenticate_user!

  def show
  end

  def profile
    @user = current_user
  end

  def update_profile
    if current_user.update(profile_params)
      if params[:from] == "signup"
        redirect_to new_plan_path, notice: "プロフィールを設定しました"
      else
        redirect_to settings_path, notice: "プロフィールを更新しました"
      end
    else
      @user = current_user
      render :profile, status: :unprocessable_entity
    end
  end

  def email
    @user = current_user
  end

  def password
  end

  def sns
  end

  def account
  end

  def visibility
  end

  def update
    current_user.update(status: params[:status])
    message = params[:status] == "active" ? "プランを公開しました" : "プランを非公開にしました"
    redirect_to visibility_settings_path, notice: message
  end

  private

  def profile_params
    params.require(:user).permit(:age_group, :gender, :residence)
  end
end
