class UserSpot < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :spot
  has_many :user_spot_tags, dependent: :destroy
  has_many :tags, through: :user_spot_tags

  # Validations
  validates :user_id, uniqueness: { scope: :spot_id }

  # Google Place types（最大2件）からタグを作成・紐付けする
  # - nil/空配列でも安全に動作
  # - blank な type はスキップ
  # - 既存関連があれば重複作成しない
  def attach_top_types!(types)
    return if types.blank?

    types.first(2).each do |type_name|
      next if type_name.blank?

      tag = Tag.find_or_create_by!(tag_name: type_name)
      user_spot_tags.find_or_create_by!(tag: tag)
    end
  end
end
