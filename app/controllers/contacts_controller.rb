# frozen_string_literal: true

class ContactsController < ApplicationController
  def new
    @contact = Contact.new
    @contact.email = current_user.email if user_signed_in?
  end

  def create
    @contact = Contact.new(contact_params)

    if @contact.valid?
      # TODO: #243でメール送信を実装
      redirect_to new_contact_path, notice: "お問い合わせを送信しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def contact_params
    params.require(:contact).permit(:category, :body, :email)
  end
end
