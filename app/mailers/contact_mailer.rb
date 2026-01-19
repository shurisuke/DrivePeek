# frozen_string_literal: true

class ContactMailer < ApplicationMailer
  ADMIN_EMAIL = "drivepeek.app@gmail.com"

  def notify_admin(contact)
    @contact = contact

    mail(
      to: ADMIN_EMAIL,
      subject: "【DrivePeek】お問い合わせ: #{contact.category_name}"
    )
  end
end
