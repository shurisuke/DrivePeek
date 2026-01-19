class Spot < ApplicationRecord
  # Associations
  has_many :like_spots, dependent: :destroy
  has_many :liked_by_users, through: :like_spots, source: :user
  has_many :plan_spots, dependent: :destroy
  has_many :plans, through: :plan_spots
  has_many :spot_genres, dependent: :destroy
  has_many :genres, through: :spot_genres

  # Validations
  validates :place_id, presence: true, uniqueness: true
  validates :name, presence: true
  validates :lat, presence: true
  validates :lng, presence: true

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

    joins(:like_spots).where(like_spots: { user_id: user.id })
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
    return false if genres.count >= 2

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

  private

  # prefecture/city が未設定なら ReverseGeocoder で補完
  def geocode_if_needed
    return if prefecture.present? && city.present?
    return unless lat.present? && lng.present?

    result = ReverseGeocoder.lookup_address(lat: lat, lng: lng)
    updates = {}
    updates[:prefecture] = result[:prefecture] if prefecture.blank? && result[:prefecture].present?
    updates[:city] = result[:city] if city.blank? && result[:city].present?
    update_columns(updates) if updates.any?
  end

  def should_clear_cities_cache?
    saved_change_to_prefecture? || saved_change_to_city? || destroyed?
  end

  def clear_cities_cache
    self.class.clear_cities_cache
  end
end
