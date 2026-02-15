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

  # 座標から既存Spotを検索、なければPlaces APIで検索して作成
  # @return [Spot, nil]
  def self.find_or_create_from_location(name:, address:, lat:, lng:)
    return nil if name.blank? || lat.zero? || lng.zero?

    # 1. 近傍の既存Spotを検索
    existing = nearby(lat: lat, lng: lng).first
    return existing if existing

    # 2. Google Places APIで検索
    place = GooglePlacesAdapter.find_place(name: name, lat: lat, lng: lng)
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
  scope :for_community, ->(keyword: nil, cities: nil, genre_ids: nil, liked_by_user: nil) {
    base = search_keyword(keyword)
      .filter_by_cities(cities)
      .filter_by_genres(genre_ids)

    base = base.liked_by(liked_by_user) if liked_by_user

    base.includes(:genres)
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

    detected_ids = GenreDetector.detect(self, count: 2)

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

  private

  # prefecture/city/town が未設定なら ReverseGeocoder で補完
  def geocode_if_needed
    return if prefecture.present? && city.present? && town.present?
    return unless lat.present? && lng.present?

    result = ReverseGeocoder.lookup_address(lat: lat, lng: lng)
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
