class User < ApplicationRecord
  # Devise modules
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable,
         :omniauthable, omniauth_providers: [ :twitter2, :line ]

  # Enums
  enum :status, { active: 0, hidden: 1 }
  enum :gender, { male: 0, female: 1, not_specified: 2 }, default: :not_specified
  enum :age_group, { teens: 0, twenties: 1, thirties: 2, forties: 3, fifties: 4, sixties_plus: 5 }

  # 都道府県リスト
  PREFECTURES = %w[
    北海道 青森県 岩手県 宮城県 秋田県 山形県 福島県
    茨城県 栃木県 群馬県 埼玉県 千葉県 東京都 神奈川県
    新潟県 富山県 石川県 福井県 山梨県 長野県 岐阜県
    静岡県 愛知県 三重県 滋賀県 京都府 大阪府 兵庫県
    奈良県 和歌山県 鳥取県 島根県 岡山県 広島県 山口県
    徳島県 香川県 愛媛県 高知県 福岡県 佐賀県 長崎県
    熊本県 大分県 宮崎県 鹿児島県 沖縄県
  ].freeze

  # 地方別都道府県
  PREFECTURES_BY_REGION = {
    "北海道・東北" => %w[北海道 青森県 岩手県 宮城県 秋田県 山形県 福島県],
    "関東" => %w[茨城県 栃木県 群馬県 埼玉県 千葉県 東京都 神奈川県],
    "中部" => %w[新潟県 富山県 石川県 福井県 山梨県 長野県 岐阜県 静岡県 愛知県],
    "近畿" => %w[三重県 滋賀県 京都府 大阪府 兵庫県 奈良県 和歌山県],
    "中国・四国" => %w[鳥取県 島根県 岡山県 広島県 山口県 徳島県 香川県 愛媛県 高知県],
    "九州・沖縄" => %w[福岡県 佐賀県 長崎県 熊本県 大分県 宮崎県 鹿児島県 沖縄県]
  }.freeze

  # SNS登録時のバリデーションスキップ用フラグ
  attr_accessor :registering_via_sns

  # Associations
  has_many :identities, dependent: :destroy
  has_many :plans, dependent: :destroy
  has_many :like_spots, dependent: :destroy
  has_many :liked_spots, through: :like_spots, source: :spot
  has_many :like_plans, dependent: :destroy
  has_many :liked_plans, through: :like_plans, source: :plan

  # Validations
  validates :email, presence: true, uniqueness: true,
                    format: { with: URI::MailTo::EMAIL_REGEXP },
                    unless: :sns_only_user?
  validates :email, uniqueness: true, allow_blank: true, if: :sns_only_user?
  validates :residence, inclusion: { in: PREFECTURES }, allow_blank: true

  # SNS認証のみのユーザーはパスワード不要
  def password_required?
    super && !sns_only_user?
  end

  # SNS認証のみのユーザーはメール不要（Deviseのvalidatableをオーバーライド）
  def email_required?
    !sns_only_user?
  end

  # SNS認証のみのユーザーはメール確認不要
  def confirmation_required?
    !sns_only_user?
  end

  # OmniAuthコールバックからユーザーを検索
  def self.from_omniauth(auth)
    Identity.find_by(provider: auth.provider, uid: auth.uid)&.user
  end

  # OmniAuthからユーザーを新規作成（SNSユーザーはメール不要）
  def self.create_from_omniauth(auth)
    user = new(
      email: nil,
      password: Devise.friendly_token[0, 20]
    )
    user.registering_via_sns = true
    user.identities.build(provider: auth.provider, uid: auth.uid)
    user.skip_confirmation!
    user.save
    user
  end

  # SNS連携を追加
  def link_omniauth(auth)
    identities.find_or_create_by(provider: auth.provider, uid: auth.uid)
  end

  # 指定したプロバイダと連携済みか
  def linked_with?(provider)
    identities.exists?(provider: provider)
  end

  # SNS認証のみのユーザーか（メールアドレス未設定）
  def sns_only_user?
    (registering_via_sns || identities.exists?) && email.blank?
  end

  # 年代表示（コメント欄用）
  def age_group_display
    return nil unless age_group
    I18n.t("enums.user.age_group.#{age_group}")
  end

  # 性別表示（コメント欄用、未設定・「回答しない」は nil を返す）
  def gender_display
    return nil if gender.blank? || not_specified?
    I18n.t("enums.user.gender.#{gender}")
  end

  # コメント欄用のプロフィール表示
  def comment_profile
    parts = []
    parts << residence if residence.present?
    age_gender = [ age_group_display, gender_display ].compact.join
    parts << age_gender if age_gender.present?
    parts.join(" / ")
  end
end
