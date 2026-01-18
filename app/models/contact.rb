# frozen_string_literal: true

class Contact
  include ActiveModel::Model
  include ActiveModel::Attributes

  CATEGORIES = %w[bug feature other].freeze

  attribute :category, :string
  attribute :body, :string
  attribute :email, :string

  validates :category, presence: true, inclusion: { in: CATEGORIES }
  validates :body, presence: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }

  def category_name
    I18n.t("contacts.categories.#{category}", default: category)
  end
end
