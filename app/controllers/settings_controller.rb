class SettingsController < ApplicationController
  before_action :authenticate_user!

  def show
  end

  def update
    current_user.update(status: params[:status])
    message = params[:status] == "active" ? "プランを公開しました" : "プランを非公開にしました"
    redirect_to edit_user_registration_path(section: :visibility), notice: message
  end
end
