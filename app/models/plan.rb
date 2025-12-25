class Plan < ApplicationRecord
  # Associations
  belongs_to :user
  has_many :plan_spots, dependent: :destroy
  has_many :spots, through: :plan_spots
  has_one :start_point, dependent: :destroy
  has_one :goal_point, dependent: :destroy
  has_many :like_plans, dependent: :destroy
  has_many :liked_by_users, through: :like_plans, source: :user

  # Scopes
  scope :with_spots, -> { joins(:plan_spots).distinct }
  scope :publicly_visible, -> { joins(:user).where(users: { status: :active }) }

  # キーワード検索（プラン名/スポット名/住所/タグで部分一致）
  # 日本語タグ名はI18n逆引きで英語キーに変換して検索
  scope :search_keyword, ->(q) {
    return all if q.blank?

    keyword = "%#{sanitize_sql_like(q)}%"

    # 日本語タグ名から英語キーを逆引き
    tag_keys = GooglePlaceTypesDictionary.keys_for(q)

    # spotsとuser_spotsを正しくJOIN
    # user_spots.spot_id = spots.id かつ user_spots.user_id = plans.user_id で制約
    base_query = left_joins(:spots)
      .joins("LEFT OUTER JOIN user_spots ON user_spots.spot_id = spots.id AND user_spots.user_id = plans.user_id")
      .joins("LEFT OUTER JOIN user_spot_tags ON user_spot_tags.user_spot_id = user_spots.id")
      .joins("LEFT OUTER JOIN tags ON tags.id = user_spot_tags.tag_id")

    base_conditions = "plans.title ILIKE :q OR spots.name ILIKE :q OR spots.address ILIKE :q OR tags.tag_name ILIKE :q"

    # 逆引きキーがあれば IN 条件を追加
    if tag_keys.present?
      base_query
        .where("#{base_conditions} OR tags.tag_name IN (:keys)", q: keyword, keys: tag_keys)
        .distinct
    else
      base_query
        .where(base_conditions, q: keyword)
        .distinct
    end
  }

  # Callbacks
  before_update :set_default_title_if_blank

  def marker_data_for_edit
    {
      start_point: lat_lng_hash(start_point),
      end_point:   lat_lng_hash(goal_point),
      spots:       spots.map { |spot| lat_lng_hash(spot) }.compact
    }
  end

  def marker_data_for_public_view
    {
      spots: spots.map { |spot| lat_lng_hash(spot) }.compact
    }
  end

  # ✅ 合計走行距離（km）
  # preload済みのplan_spotsがあればRubyで計算、なければSQLで計算
  def total_distance
    distance = start_point&.move_distance.to_f
    distance += if plan_spots.loaded?
                  plan_spots.sum(&:move_distance)
                else
                  plan_spots.sum(:move_distance)
                end
    distance.round(1)
  end

  # ✅ 合計移動時間（分）
  # preload済みのplan_spotsがあればRubyで計算、なければSQLで計算
  def total_move_time
    time = start_point&.move_time.to_i
    time += if plan_spots.loaded?
              plan_spots.sum(&:move_time)
            else
              plan_spots.sum(:move_time)
            end
    time
  end

  # ✅ 合計移動時間（フォーマット済み文字列）
  def formatted_move_time
    minutes = total_move_time
    return "0分" if minutes.zero?

    hours = minutes / 60
    remaining_minutes = minutes % 60

    if hours.positive?
      "#{hours}時間#{remaining_minutes}分"
    else
      "#{remaining_minutes}分"
    end
  end

  # ✅ 合計有料道路料金
  def total_toll_cost
    cost = 0
    cost += start_point.move_cost.to_i if start_point&.toll_used?
    cost += plan_spots.where(toll_used: true).sum(:move_cost)
    cost
  end

  # ✅ 有料道路使用の有無
  def has_toll_roads?
    return true if start_point&.toll_used?
    plan_spots.exists?(toll_used: true)
  end

  private

  def lat_lng_hash(record)
    return nil unless record&.lat.present? && record&.lng.present?
    { lat: record.lat, lng: record.lng }
  end

  def set_default_title_if_blank
    if title.blank?
      cities = spots.map(&:city).uniq.compact
     self.title = if cities.any?
                     "#{cities.join('・')}の旅"
                   else
                     "ドライブプラン"
                   end
    end
  end
end
