# frozen_string_literal: true

class Contact
  include ActiveModel::Model
  include ActiveModel::Attributes

  CATEGORIES = %w[bug feature other].freeze

  attribute :category, :string
  attribute :body, :string
  attribute :email, :string

  validates :category, presence: true, inclusion: { in: CATEGORIES }
  validates :body, presence: true, length: { minimum: 10 }
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }

  def category_name
    I18n.t("contacts.categories.#{category}", default: category)
  end

  def submit
    return false unless valid?

    ContactMailer.notify_admin(self).deliver_now
    true
  rescue StandardError => e
    Rails.logger.error "[CONTACT] メール送信失敗: #{e.message}"
    errors.add(:base, "送信に失敗しました。時間をおいて再度お試しください。")
    false
  end
end
