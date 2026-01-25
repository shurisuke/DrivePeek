module Api
  class AiChatsController < ApplicationController
    before_action :authenticate_user!
    before_action :set_plan

    def create
      return head :unprocessable_entity if user_message.blank?

      @result = AiChatMessage.chat(plan: @plan, user: current_user, message: user_message, mode: mode)

      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to edit_plan_path(@plan) }
      end
    end

    def destroy_all
      @plan.ai_chat_messages.destroy_all

      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to edit_plan_path(@plan) }
      end
    end

    private

    def set_plan
      @plan = current_user.plans.find(params[:plan_id])
    end

    def user_message
      @user_message ||= params[:message].to_s.strip
    end

    def mode
      @mode ||= params[:mode].to_s.presence_in(%w[plan spot]) || "plan"
    end
  end
end
