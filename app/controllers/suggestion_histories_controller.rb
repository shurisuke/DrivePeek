# app/controllers/suggestion_histories_controller.rb
class SuggestionHistoriesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_plan

  # DELETE /suggestion_history
  def destroy
    @plan.suggestions.destroy_all

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to edit_plan_path(@plan) }
    end
  end

  private

  def set_plan
    @plan = current_user.plans.find(params[:plan_id])
  end
end
