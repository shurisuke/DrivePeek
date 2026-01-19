# frozen_string_literal: true

class ContactsController < ApplicationController
  rate_limit to: 3, within: 5.minutes, only: :create, with: -> { redirect_to new_contact_path, alert: "送信回数の上限に達しました。しばらくしてからお試しください。" }
  before_action :reject_spam, only: :create

  def new
    @contact = Contact.new
    @contact.email = current_user.email if user_signed_in?
  end

  def create
    @contact = Contact.new(contact_params)

    if @contact.submit
      redirect_to new_contact_path, notice: "お問い合わせを送信しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def reject_spam
    return unless params[:website].present?

    Rails.logger.warn "[SPAM] Honeypot triggered: IP=#{request.remote_ip}"
    redirect_to new_contact_path, notice: "お問い合わせを送信しました"
  end

  def contact_params
    params.require(:contact).permit(:category, :body, :email)
  end
end
