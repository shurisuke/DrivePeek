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

  # みんなのプラン用のベースRelation（検索・includes・並び順を含む）
  scope :for_community, ->(keyword: nil, cities: nil, genre_ids: nil) {
    publicly_visible
      .with_spots
      .search_keyword(keyword)
      .filter_by_cities(cities)
      .filter_by_genres(genre_ids)
      .includes(:user, :start_point, plan_spots: { spot: :genres })
      .order(updated_at: :desc)
  }

  # 市区町村で絞り込み（複数対応）
  # cities は "都道府県/市区町村" 形式の配列
  scope :filter_by_cities, ->(cities) {
    valid_cities = Array(cities).reject(&:blank?)
    return all if valid_cities.empty?

    conditions = valid_cities.map do |city|
      prefecture, city_name = city.split("/", 2)
      if city_name.present?
        sanitize_sql_array([ "(spots.prefecture = ? AND spots.city = ?)", prefecture, city_name ])
      else
        sanitize_sql_array([ "spots.prefecture = ?", prefecture ])
      end
    end

    joins(:spots).where(conditions.join(" OR ")).distinct
  }

  # ジャンルで絞り込み（複数対応）
  scope :filter_by_genres, ->(genre_ids) {
    valid_ids = Array(genre_ids).map(&:to_i).reject(&:zero?)
    return all if valid_ids.empty?

    joins(spots: :spot_genres).where(spot_genres: { genre_id: valid_ids }).distinct
  }

  # キーワード検索（プラン名/スポット名/住所で部分一致）
  scope :search_keyword, ->(q) {
    return all if q.blank?

    keyword = "%#{sanitize_sql_like(q)}%"

    left_joins(:spots)
      .where("plans.title ILIKE :q OR spots.name ILIKE :q OR spots.address ILIKE :q", q: keyword)
      .distinct
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
