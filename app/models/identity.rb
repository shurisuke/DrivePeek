class Identity < ApplicationRecord
  belongs_to :user

  validates :provider, presence: true
  validates :uid, presence: true, uniqueness: { scope: :provider }

  # プロバイダの表示名（クラスメソッド）
  def self.provider_name_for(provider)
    case provider
    when "twitter2" then "X"
    when "line" then "LINE"
    else provider.to_s.titleize
    end
  end

  # プロバイダの表示名（インスタンスメソッド）
  def provider_name
    self.class.provider_name_for(provider)
  end
end
