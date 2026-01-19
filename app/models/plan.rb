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
  scope :with_multiple_spots, -> {
    where("(SELECT COUNT(*) FROM plan_spots WHERE plan_spots.plan_id = plans.id) >= 2")
  }
  scope :publicly_visible, -> { joins(:user).where(users: { status: :active }) }

  # みんなのプラン用のベースRelation（検索・includes・並び順を含む）
  # スポットが2つ以上あるプランのみ表示
  scope :for_community, ->(keyword: nil, cities: nil, genre_ids: nil, liked_by_user: nil) {
    base = publicly_visible
      .with_multiple_spots
      .search_keyword(keyword)
      .filter_by_cities(cities)
      .filter_by_genres(genre_ids)

    base = base.liked_by(liked_by_user) if liked_by_user

    base.includes(:user, :start_point, plan_spots: { spot: :genres })
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

  # 特定ユーザーがお気に入りしたプランのみ
  scope :liked_by, ->(user) {
    return none unless user

    joins(:like_plans).where(like_plans: { user_id: user.id })
  }

  # ジャンルで絞り込み（複数対応）
  # 親ジャンル選択時は子ジャンルも含めて検索
  scope :filter_by_genres, ->(genre_ids) {
    valid_ids = Array(genre_ids).map(&:to_i).reject(&:zero?)
    return all if valid_ids.empty?

    # 選択されたジャンルに子がある場合、子ジャンルのIDも追加
    expanded_ids = Genre.where(id: valid_ids).includes(:children).flat_map do |genre|
      [ genre.id ] + genre.children.pluck(:id)
    end.uniq

    joins(spots: :spot_genres).where(spot_genres: { genre_id: expanded_ids }).distinct
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

  # コミュニティプランプレビュー用（マーカー + ポリライン）
  def preview_data
    ordered_plan_spots = plan_spots.loaded? ? plan_spots.sort_by(&:position) : plan_spots.order(:position).to_a

    {
      spots: ordered_plan_spots.map do |ps|
        {
          id: ps.spot.id,
          lat: ps.spot.lat,
          lng: ps.spot.lng,
          name: ps.spot.name,
          address: ps.spot.address,
          place_id: ps.spot.place_id,
          genres: ps.spot.genres.first(2).map(&:name)
        }
      end,
      # スポット間のポリラインのみ（最後のスポット→帰宅は除外）
      polylines: ordered_plan_spots[0..-2].map(&:polyline).compact
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

  # ✅ スポット間のみの合計距離（公開用：start→spot1 と lastSpot→goal を除く）
  def spots_only_distance
    ordered_spots = plan_spots.loaded? ? plan_spots.sort_by(&:position) : plan_spots.order(:position).to_a
    return 0.0 if ordered_spots.size < 2

    # 最後のスポット以外の move_distance を合計
    ordered_spots[0..-2].sum(&:move_distance).to_f.round(1)
  end

  # ✅ スポット間のみの合計時間（公開用：start→spot1 と lastSpot→goal を除く）
  def spots_only_move_time
    ordered_spots = plan_spots.loaded? ? plan_spots.sort_by(&:position) : plan_spots.order(:position).to_a
    return 0 if ordered_spots.size < 2

    # 最後のスポット以外の move_time を合計
    ordered_spots[0..-2].sum(&:move_time).to_i
  end

  # ✅ 出発地点→最後のスポットまでの距離（帰宅地点を除く）
  def start_to_last_spot_distance
    ordered_spots = plan_spots.loaded? ? plan_spots.sort_by(&:position) : plan_spots.order(:position).to_a
    return 0.0 if ordered_spots.empty?

    distance = start_point&.move_distance.to_f
    # 最後のスポット以外の move_distance を合計（最後のスポットは帰宅地点への距離）
    distance += ordered_spots[0..-2].sum(&:move_distance) if ordered_spots.size > 1
    distance.round(1)
  end

  # ✅ 出発地点→最後のスポットまでの時間（帰宅地点を除く）
  def start_to_last_spot_move_time
    ordered_spots = plan_spots.loaded? ? plan_spots.sort_by(&:position) : plan_spots.order(:position).to_a
    return 0 if ordered_spots.empty?

    time = start_point&.move_time.to_i
    # 最後のスポット以外の move_time を合計（最後のスポットは帰宅地点への時間）
    time += ordered_spots[0..-2].sum(&:move_time) if ordered_spots.size > 1
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

  # ================================================================
  # ファクトリメソッド
  # ================================================================

  # 位置情報からプランを作成（出発地点・帰宅地点を同時に設定）
  def self.create_with_location(user:, lat:, lng:)
    transaction do
      plan = create!(user: user, title: "")

      start_point = StartPoint.build_from_location(plan: plan, lat: lat, lng: lng)
      plan.start_point = start_point
      plan.save!

      goal_point = GoalPoint.build_from_start_point(plan: plan, start_point: start_point)
      plan.goal_point = goal_point
      plan.save!

      plan
    end
  end

  # ================================================================
  # 再計算
  # ================================================================

  # 関連モデルの変更に応じて再計算を実行する
  # @param changed_model [StartPoint, GoalPoint, PlanSpot] 変更されたモデル
  # @param action [Symbol] :update, :create, :destroy, :reorder
  def recalculate_for!(changed_model, action: :update)
    case action
    when :create, :destroy, :reorder
      # 追加・削除・並び替えは常に経路再計算
      recalculator.recalculate!(route: true, schedule: true)
    when :update
      recalculate_for_update!(changed_model)
    end
  end

  private

  def recalculator
    Plan::Recalculator.new(self)
  end

  def recalculate_for_update!(changed_model)
    if changed_model.route_affecting_changes?
      recalculator.recalculate!(route: true, schedule: true)
    elsif changed_model.schedule_affecting_changes?
      recalculator.recalculate!(schedule: true)
    end
  end

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
