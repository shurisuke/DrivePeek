# 責務: ドライブプラン全体を管理し、関連モデルの操作を統括
#
# 構造:
#   - start_point: 出発地点（1つ）
#   - plan_spots: 経由スポット（0個以上、position順）
#   - goal_point: 到着地点（1つ）
#
# 再計算の委譲:
#   - 経路計算 → Plan::Driving
#   - 時刻計算 → Plan::Timetable
#   - 統括     → Plan::Recalculator
#
# 原則:
#   - スポット操作（追加・削除・並替）後は recalculate_for! を呼ぶ
#   - 集計（総距離・総時間）は Plan::Totals concern で提供
#
class Plan < ApplicationRecord
  include Plan::Totals

  # Associations
  belongs_to :user
  has_many :plan_spots, dependent: :destroy
  has_many :spots, through: :plan_spots
  has_one :start_point, dependent: :destroy
  has_one :goal_point, dependent: :destroy
  has_many :favorite_plans, dependent: :destroy
  has_many :liked_by_users, through: :favorite_plans, source: :user
  has_many :suggestions, dependent: :destroy

  # Scopes
  scope :with_multiple_spots, -> { where("plan_spots_count >= 2") }
  scope :publicly_visible, -> { joins(:user).where(users: { status: :active }) }

  # 円内のスポットを含むプランを検索
  # @param center_lat [Float] 中心緯度
  # @param center_lng [Float] 中心経度
  # @param radius_km [Float] 半径（km）
  # EXISTS方式でDISTINCT + ORDER BYの衝突を回避
  scope :within_circle, ->(center_lat, center_lng, radius_km) {
    return all if center_lat.blank? || center_lng.blank? || radius_km.blank?

    distance_sql = sanitize_sql_array([
      "SQRT(POW((spots.lat - ?) * 111.0, 2) + POW((spots.lng - ?) * 91.0, 2)) <= ?",
      center_lat, center_lng, radius_km
    ])
    where("EXISTS (SELECT 1 FROM plan_spots JOIN spots ON spots.id = plan_spots.spot_id WHERE plan_spots.plan_id = plans.id AND #{distance_sql})")
  }

  # みんなのプラン用のベースRelation（検索・includes・並び順を含む）
  # スポットが2つ以上あるプランのみ表示
  # @param circle [Hash, nil] { center_lat:, center_lng:, radius_km: }
  # @param sort [String] "newest" | "oldest" | "popular"
  scope :for_community, ->(keyword: nil, cities: nil, genre_ids: nil, liked_by_user: nil, circle: nil, sort: "newest") {
    base = publicly_visible
      .with_multiple_spots
      .search_keyword(keyword)
      .filter_by_cities(cities)
      .filter_by_genres(genre_ids)

    base = base.liked_by(liked_by_user) if liked_by_user
    base = base.within_circle(circle[:center_lat], circle[:center_lng], circle[:radius_km]) if circle.present?

    base.preload(:user, :start_point, plan_spots: { spot: :genres })
        .sort_by_option(sort)
  }

  # ソートオプション
  scope :sort_by_option, ->(sort) {
    case sort
    when "oldest"
      order(created_at: :asc)
    when "popular"
      order(favorite_plans_count: :desc, created_at: :desc)
    else # newest
      order(created_at: :desc)
    end
  }

  # 市区町村で絞り込み（複数対応）
  # cities は "都道府県/市区町村" 形式の配列
  # EXISTS方式でDISTINCT + ORDER BYの衝突を回避
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

    where("EXISTS (SELECT 1 FROM plan_spots JOIN spots ON spots.id = plan_spots.spot_id WHERE plan_spots.plan_id = plans.id AND (#{conditions.join(' OR ')}))")
  }

  # 特定ユーザーがお気に入りしたプランのみ
  scope :liked_by, ->(user) {
    return none unless user

    joins(:favorite_plans).where(favorite_plans: { user_id: user.id })
  }

  # ジャンルで絞り込み（複数対応）
  # 親ジャンル選択時は子ジャンルも、子ジャンル選択時は親ジャンルも含めて検索
  # EXISTS方式でDISTINCT + ORDER BYの衝突を回避
  scope :filter_by_genres, ->(genre_ids) {
    expanded_ids = Genre.expand_family(genre_ids)
    return all if expanded_ids.empty?

    where("EXISTS (SELECT 1 FROM plan_spots JOIN spot_genres ON spot_genres.spot_id = plan_spots.spot_id WHERE plan_spots.plan_id = plans.id AND spot_genres.genre_id IN (?))", expanded_ids)
  }

  # キーワード検索（プラン名/スポット名/住所で部分一致）
  # EXISTS方式でDISTINCT + ORDER BYの衝突を回避
  scope :search_keyword, ->(q) {
    return all if q.blank?

    keyword = "%#{sanitize_sql_like(q)}%"

    where(
      "plans.title ILIKE :q OR EXISTS (SELECT 1 FROM plan_spots JOIN spots ON spots.id = plan_spots.spot_id WHERE plan_spots.plan_id = plans.id AND (spots.name ILIKE :q OR spots.address ILIKE :q))",
      q: keyword
    )
  }

  # 空プランを除外（タイトル空 + スポット0件）
  scope :exclude_stale_empty, -> {
    where.not(title: [ "", nil ])
      .or(where(id: joins(:plan_spots).select(:id)))
  }

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

  # 関連プラン（同じcityを含むプラン）
  def related_plans(limit: 5)
    cities = spots.pluck(:prefecture, :city)
                  .filter { |pref, city| pref.present? && city.present? }
                  .map { |pref, city| "#{pref}/#{city}" }
                  .uniq
    return Plan.none if cities.empty?

    Plan.publicly_visible
        .with_multiple_spots
        .filter_by_cities(cities)
        .where.not(id: id)
        .includes(:user, plan_spots: { spot: :genres })
        .order(created_at: :desc)
        .limit(limit)
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
  # スポット操作（採用・並び替え）
  # ================================================================

  # 他のプランからスポットをコピー（タイトル・出発地点・帰宅地点はコピーしない）
  # @param source [Plan] コピー元プラン
  def copy_spots_from(source)
    return if source.blank?

    transaction do
      source.plan_spots.order(:position).each do |ps|
        plan_spots.create!(
          spot_id: ps.spot_id,
          position: ps.position,
          stay_duration: ps.stay_duration
        )
      end

      recalculate_for!(nil, action: :create)
    end
  end

  # スポットを一括置換して経路再計算（AI提案の採用）
  # @param spot_ids [Array<Integer>] spot ID配列（検証済み）
  def adopt_spots!(spot_ids)
    transaction do
      plan_spots.destroy_all
      spot_ids.each { |id| plan_spots.create!(spot_id: id) }
      recalculate_for!(nil, action: :create)
    end
  end

  # スポットの並び順を変更して経路再計算
  # @param ordered_ids [Array] 並び替え後のplan_spot ID配列（検証済み）
  def reorder_spots!(ordered_ids)
    transaction do
      PlanSpot.reorder_for_plan!(plan: self, ordered_ids: ordered_ids.map(&:to_i))
      recalculate_for!(nil, action: :reorder)
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

  # position順に並んだplan_spotsを返す
  # preload済みならRubyでソート、未ロードならSQLでorder
  def ordered_plan_spots
    plan_spots.loaded? ? plan_spots.sort_by(&:position) : plan_spots.order(:position).to_a
  end

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
    return nil unless record&.lat && record&.lng
    { lat: record.lat, lng: record.lng }
  end
end
