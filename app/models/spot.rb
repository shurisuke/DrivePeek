# 責務: 観光スポット・飲食店などの場所情報を管理
#
# 主な機能:
#   - Google Places API との連携（検索・詳細取得）
#   - 位置情報による検索（円内検索・近傍検索）
#   - ジャンル・市区町村によるフィルタリング
#   - AIによるジャンル自動判定
#
# 関連モデル:
#   - Plan: plan_spots を通じて多対多
#   - Genre: spot_genres を通じて多対多
#   - User: favorite_spots を通じてお気に入り
#
class Spot < ApplicationRecord
  # Associations
  has_many :favorite_spots, dependent: :destroy
  has_many :liked_by_users, through: :favorite_spots, source: :user
  has_many :plan_spots, dependent: :destroy
  has_many :plans, through: :plan_spots
  has_many :spot_genres, dependent: :destroy
  has_many :genres, through: :spot_genres
  has_many :spot_comments, dependent: :destroy

  # Validations
  validates :place_id, presence: true, uniqueness: true
  validates :name, presence: true
  validates :lat, presence: true
  validates :lng, presence: true

  # 近傍検索の閾値（0.001度 ≈ 約100m）
  PROXIMITY_THRESHOLD = 0.001

  # 表示範囲内の人気スポットを取得（お気に入り数順）
  scope :popular_in_bounds, ->(north:, south:, east:, west:, genre_ids: nil, limit: 10) {
    base = where(lat: south..north, lng: west..east)
           .left_joins(:favorite_spots)
           .group(:id)
           .select("spots.*, COUNT(favorite_spots.id) AS favorites_count")
           .order("favorites_count DESC")
           .limit(limit)

    genre_ids.present? ? base.filter_by_genres(genre_ids.map(&:to_i)) : base
  }

  # 近傍のSpotを検索
  scope :nearby, ->(lat:, lng:, threshold: PROXIMITY_THRESHOLD) {
    where(lat: (lat - threshold)..(lat + threshold))
      .where(lng: (lng - threshold)..(lng + threshold))
  }

  # 円内のスポットを検索（緯度1度≈111km、経度1度≈91km で概算）
  # @param center_lat [Float] 中心緯度
  # @param center_lng [Float] 中心経度
  # @param radius_km [Float] 半径（km）
  scope :within_circle, ->(center_lat, center_lng, radius_km) {
    return none if center_lat.blank? || center_lng.blank? || radius_km.blank?

    distance_sql = "SQRT(POW((spots.lat - ?) * 111.0, 2) + POW((spots.lng - ?) * 91.0, 2))"
    where("#{distance_sql} <= ?", center_lat, center_lng, radius_km)
  }

  # place_idからSpotを検索/作成し、写真URLも返す
  # @param place_id [String] Google Place ID
  # @param fallback [Hash] { name:, address:, lat:, lng: } 新規作成時のフォールバック値
  # @return [Array(Spot, Array)] [spot, photo_urls]
  def self.find_or_create_with_photos(place_id:, fallback: {})
    return [ nil, [] ] if place_id.blank?

    spot = find_or_initialize_by(place_id: place_id)
    details = GoogleApi::Places.fetch_details(place_id, include_photos: true)

    if spot.new_record?
      spot.update!(
        name: details&.dig(:name) || fallback[:name] || "名称不明",
        address: details&.dig(:address) || fallback[:address] || "住所不明",
        lat: fallback[:lat],
        lng: fallback[:lng]
      )
    end

    [ spot, details&.dig(:photo_urls) || [] ]
  end

  # 座標から既存Spotを検索、なければPlaces APIで検索して作成
  # @return [Spot, nil]
  def self.find_or_create_from_location(name:, address:, lat:, lng:)
    return nil if name.blank? || lat.zero? || lng.zero?

    # 1. 近傍の既存Spotを検索
    existing = nearby(lat: lat, lng: lng).first
    return existing if existing

    # 2. Google Places APIで検索
    place = GoogleApi::Places.find_by_name(name, lat: lat, lng: lng)
    return nil unless place

    # 3. place_idで検索、なければ作成
    find_or_create_by!(place_id: place[:place_id]) do |spot|
      spot.name = place[:name] || name
      spot.address = address
      spot.lat = place[:lat] || lat
      spot.lng = place[:lng] || lng
    end
  end

  # Callbacks
  after_commit :geocode_if_needed, on: %i[create update]
  after_commit :clear_cities_cache, if: :should_clear_cities_cache?

  CITIES_CACHE_KEY = "spots/cities_by_prefecture".freeze

  # みんなのスポット用のベースRelation（検索・includes・並び順を含む）
  # @param circle [Hash, nil] { center_lat:, center_lng:, radius_km: }
  # @param sort [String] "newest" | "oldest" | "popular"
  scope :for_community, ->(keyword: nil, cities: nil, genre_ids: nil, liked_by_user: nil, circle: nil, sort: "newest") {
    base = search_keyword(keyword)
      .filter_by_cities(cities)
      .filter_by_genres(genre_ids)

    base = base.liked_by(liked_by_user) if liked_by_user
    base = base.within_circle(circle[:center_lat], circle[:center_lng], circle[:radius_km]) if circle.present?

    base.includes(:genres)
        .sort_by_option(sort)
  }

  # ソートオプション
  scope :sort_by_option, ->(sort) {
    case sort
    when "oldest"
      order(created_at: :asc)
    when "popular"
      order(favorite_spots_count: :desc, created_at: :desc)
    else # newest
      order(created_at: :desc)
    end
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

    where(conditions.join(" OR "))
  }

  # 特定ユーザーがお気に入りしたスポットのみ
  scope :liked_by, ->(user) {
    return none unless user

    joins(:favorite_spots).where(favorite_spots: { user_id: user.id })
  }

  # ジャンルで絞り込み（複数対応）
  # 親ジャンル選択時は子ジャンルも、子ジャンル選択時は親ジャンルも含めて検索
  scope :filter_by_genres, ->(genre_ids) {
    expanded_ids = Genre.expand_family(genre_ids)
    return all if expanded_ids.empty?

    joins(:spot_genres).where(spot_genres: { genre_id: expanded_ids }).distinct
  }

  # キーワード検索（スポット名/住所で部分一致）
  scope :search_keyword, ->(q) {
    return all if q.blank?

    keyword = "%#{sanitize_sql_like(q)}%"
    where("spots.name ILIKE :q OR spots.address ILIKE :q", q: keyword)
  }

  # 都道府県ごとの市区町村リストを返す（キャッシュ付き）
  # 戻り値: { "北海道" => ["札幌市", "函館市", ...], "東京都" => [...], ... }
  def self.cities_by_prefecture
    Rails.cache.fetch(CITIES_CACHE_KEY, expires_in: 1.hour) do
      where.not(prefecture: [ nil, "" ]).where.not(city: [ nil, "" ])
           .distinct.pluck(:prefecture, :city)
           .group_by(&:first)
           .transform_values { |pairs| pairs.map(&:last).sort }
    end
  end

  def self.clear_cities_cache
    Rails.cache.delete(CITIES_CACHE_KEY)
  end

  # AIでジャンルを判定して割り当てる（遅延ロード用）
  # @return [Boolean] 判定が行われたか
  def detect_genres!
    return false if genres.exists?

    detected_ids = Genre::Detector.detect(self, count: 2)

    # AI失敗時は facility をフォールバック（無限ループ防止）
    if detected_ids.empty?
      facility = Genre.find_by(slug: "facility")
      detected_ids = [ facility.id ] if facility
    end

    detected_ids.each { |genre_id| spot_genres.find_or_create_by!(genre_id: genre_id) }
    detected_ids.any?
  rescue StandardError => e
    Rails.logger.error "[Spot##{id}] ジャンル判定エラー: #{e.message}"
    false
  end

  # 短縮住所（県+市+町）
  def short_address
    [ prefecture, city, town ].compact_blank.join
  end

  # 関連スポット（近く + 同じジャンル）
  def related_spots(limit: 5)
    return Spot.none if lat.blank? || lng.blank? || genre_ids.blank?

    Spot.within_circle(lat, lng, 5)
        .filter_by_genres(genre_ids)
        .where.not(id: id)
        .includes(:genres)
        .limit(limit)
  end

  # スポットカード表示用データを一括プリロード（N+1回避）
  # @param spots [Array<Spot>] スポット配列
  # @param user [User, nil] ログインユーザー
  # @return [Hash] { spot_stats: Hash, user_favorite_spots: Hash }
  def self.preload_card_data(spots, user)
    return { spot_stats: {}, user_favorite_spots: {} } if spots.blank?

    spot_ids = spots.map(&:id)

    # 各種カウントを一括取得
    plans_counts = PlanSpot.where(spot_id: spot_ids).group(:spot_id).count
    comments_counts = SpotComment.where(spot_id: spot_ids).group(:spot_id).count
    favorites_counts = FavoriteSpot.where(spot_id: spot_ids).group(:spot_id).count

    spot_stats = spot_ids.each_with_object({}) do |spot_id, hash|
      hash[spot_id] = {
        plans_count: plans_counts[spot_id] || 0,
        comments_count: comments_counts[spot_id] || 0,
        favorites_count: favorites_counts[spot_id] || 0
      }
    end

    user_favorite_spots = user ? user.favorite_spots.where(spot_id: spot_ids).index_by(&:spot_id) : {}

    { spot_stats: spot_stats, user_favorite_spots: user_favorite_spots }
  end

  private

  # prefecture/city/town が未設定なら GoogleApi::Geocoder で補完
  def geocode_if_needed
    return if prefecture.present? && city.present? && town.present?
    return unless lat.present? && lng.present?

    result = GoogleApi::Geocoder.reverse(lat: lat, lng: lng)
    return unless result

    updates = {}
    updates[:prefecture] = result[:prefecture] if prefecture.blank? && result[:prefecture].present?
    updates[:city] = result[:city] if city.blank? && result[:city].present?
    updates[:town] = result[:town] if town.blank? && result[:town].present?
    update_columns(updates) if updates.any?
  end

  def should_clear_cities_cache?
    saved_change_to_prefecture? || saved_change_to_city? || destroyed?
  end

  def clear_cities_cache
    self.class.clear_cities_cache
  end
end
