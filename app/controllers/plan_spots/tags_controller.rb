# app/controllers/plan_spots/tags_controller.rb
class PlanSpots::TagsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_plan
  before_action :set_plan_spot
  before_action :set_user_spot

  def create
    tag_name = params.dig(:tag, :tag_name).to_s.strip
    return head :unprocessable_entity if tag_name.blank?

    tag = Tag.find_or_create_by(tag_name: tag_name)
    @user_spot.user_spot_tags.find_or_create_by(tag: tag)

    @tags = @user_spot.tags
  end

  # DELETE /plans/:plan_id/plan_spots/:plan_spot_id/tags/:id
  # :id は tag_id として扱う
  def destroy
    tag = Tag.find_by(id: params[:id])
    return head :not_found unless tag

    user_spot_tag = @user_spot.user_spot_tags.find_by(tag: tag)
    user_spot_tag&.destroy

    @tags = @user_spot.tags
  end

  private

  def set_plan
    @plan = current_user.plans.find(params[:plan_id])
  end

  def set_plan_spot
    @plan_spot = @plan.plan_spots.includes(:spot).find(params[:plan_spot_id])
  end

  def set_user_spot
    # タグは user_spots に紐づくため、spot 経由で user_spot を確保する
    @user_spot = current_user.user_spots.find_or_create_by(spot: @plan_spot.spot)
  end
end