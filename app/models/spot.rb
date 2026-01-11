class Spot < ApplicationRecord
  # Associations
  has_many :user_spots, dependent: :destroy
  has_many :users, through: :user_spots
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
  scope :filter_by_genres, ->(genre_ids) {
    valid_ids = Array(genre_ids).map(&:to_i).reject(&:zero?)
    return all if valid_ids.empty?

    joins(:spot_genres).where(spot_genres: { genre_id: valid_ids }).distinct
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

  # photo_reference から写真URLを生成
  def photo_url(max_width: 520)
    return nil if photo_reference.blank?

    api_key = ENV["GOOGLE_MAPS_API_KEY"]
    return nil if api_key.blank?

    "https://maps.googleapis.com/maps/api/place/photo?maxwidth=#{max_width}&photo_reference=#{photo_reference}&key=#{api_key}"
  end

  # Google Places のペイロードを適用
  # - 新規: 全属性をセット
  # - 既存: 空欄のみ補完、photo_reference は常に更新（鮮度優先）
  def apply_google_payload(payload)
    payload = payload.to_h.with_indifferent_access

    self.name    ||= payload[:name]
    self.address ||= payload[:address]
    self.lat     ||= payload[:lat]
    self.lng     ||= payload[:lng]

    # photo_reference は鮮度優先で上書き
    self.photo_reference = payload[:photo_reference] if payload[:photo_reference].present?

    # prefecture / city は ReverseGeocoder で補完
    geocode_if_needed
  end

  private

  def geocode_if_needed
    return if prefecture.present? && city.present?
    return unless lat.present? && lng.present?

    result = ReverseGeocoder.lookup_address(lat: lat, lng: lng)
    self.prefecture ||= result[:prefecture]
    self.city       ||= result[:city]
  end

  def should_clear_cities_cache?
    saved_change_to_prefecture? || saved_change_to_city? || destroyed?
  end

  def clear_cities_cache
    self.class.clear_cities_cache
  end
end
