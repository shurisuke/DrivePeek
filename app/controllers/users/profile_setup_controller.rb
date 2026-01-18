class Users::ProfileSetupController < ApplicationController
  before_action :authenticate_user!

  def edit
    @user = current_user
  end

  def update
    if current_user.update(profile_params)
      if params[:from] == "signup"
        redirect_to new_plan_path, notice: "プロフィールを設定しました"
      else
        redirect_to settings_path, notice: "プロフィールを更新しました"
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def profile_params
    params.require(:user).permit(:age_group, :gender, :residence)
  end
end
