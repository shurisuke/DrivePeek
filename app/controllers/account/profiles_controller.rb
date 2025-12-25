class Account::ProfilesController < ApplicationController
  def show
  end

  def edit
  end

  def update
    if current_user.update(profile_params)
      respond_to do |format|
        format.html { redirect_to account_profile_path, notice: "設定を更新しました" }
        format.json { render json: { success: true, message: "設定を更新しました" } }
      end
    else
      respond_to do |format|
        format.html { redirect_to account_profile_path, alert: "更新に失敗しました" }
        format.json { render json: { success: false, errors: current_user.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  private

  def profile_params
    params.require(:user).permit(:status)
  end
end
