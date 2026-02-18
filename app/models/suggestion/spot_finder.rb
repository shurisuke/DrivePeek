# frozen_string_literal: true

# 円内スポット検索を担当
#
# 使い方:
#   finder = Suggestion::SpotFinder.new(35.6, 139.7, 10.0)
#   slot_data = finder.fetch_for_slots(slots)
#
class Suggestion::SpotFinder
  # 緯度1度 ≈ 111km、経度1度 ≈ 91km（日本の緯度で概算）
  LAT_KM = 111.0
  LNG_KM = 91.0

  def initialize(center_lat, center_lng, radius_km)
    @center_lat = center_lat
    @center_lng = center_lng
    @radius_km = radius_km
  end

  # プランモード用: 各スロットに対して候補スポットを取得（人気順10件）
  # @param slots [Array<Hash>] [{ genre_id: 5 }, ...] genre_id は nil 可
  # @param priority_genre_ids [Array<Integer>] 優先ジャンルID（空スロット埋め・フォールバック用）
  # @return [Array<Hash>] [{ genre_name:, candidates: [spot_hash, ...] }, ...]
  def fetch_for_slots(slots, priority_genre_ids: [])
    queue = priority_genre_ids.dup
    used_spot_ids = Set.new
    used_genre_ids = Set.new

    # ユーザー選択済みジャンルをキューから除外
    slots.each { |s| queue.delete(s[:genre_id]) if s[:genre_id] }

    slots.filter_map do |slot|
      find_first_available(slot[:genre_id], queue, used_spot_ids, used_genre_ids)
    end
  end

  private

  # 指定ジャンル → キュー → 全ジャンル の順で候補を探す
  def find_first_available(preferred_id, queue, used_spot_ids, used_genre_ids)
    genre_ids_to_try = [ preferred_id, *queue ].compact
    genre_ids_to_try << nil  # お任せフォールバック

    genre_ids_to_try.each do |genre_id|
      candidates = fetch_candidates(genre_id, 10, excluded_genre_ids: genre_id.nil? ? used_genre_ids : nil)
      candidates.reject! { |c| used_spot_ids.include?(c[:id]) }

      # 主要ジャンルが使用済みのスポットを除外（全ケース共通）
      candidates.reject! do |c|
        primary_id = extract_primary_genre_id(c)
        primary_id && used_genre_ids.include?(primary_id)
      end

      next if candidates.empty?

      queue.delete(genre_id)
      used_spot_ids.merge(candidates.map { |c| c[:id] })

      # 使用した主要ジャンルを記録（キュー選択時もnilフォールバック時も同様）
      primary_genre_id = extract_primary_genre_id(candidates.first)
      used_genre_ids.add(primary_genre_id) if primary_genre_id

      genre = genre_id ? Genre.find_by(id: genre_id) : nil
      return { genre_name: genre&.name || "おすすめ", candidates: candidates }
    end
    nil
  end

  # ジャンル名→IDのキャッシュ（N+1クエリ防止）
  def genre_id_cache
    @genre_id_cache ||= Genre.where(visible: true).pluck(:name, :id).to_h
  end

  # スポットの主要ジャンルIDを取得（表示ジャンルの最初のもの）
  def extract_primary_genre_id(spot_hash)
    return nil unless spot_hash && spot_hash[:genres].present?
    genre_id_cache[spot_hash[:genres].first]
  end

  # 候補スポットを人気順で取得
  # @param genre_id [Integer, nil] ジャンルID（nilの場合は全ジャンル、ただし「その他」カテゴリは除外）
  # @param excluded_genre_ids [Set, nil] 除外するジャンルID（nilフォールバック時のジャンル被り防止用）
  def fetch_candidates(genre_id, limit, excluded_genre_ids: nil)
    scope = spots_in_circle

    if genre_id
      expanded_ids = Genre.expand_family([ genre_id ])
      scope = scope.joins(:spot_genres).where(spot_genres: { genre_id: expanded_ids })
    else
      # お任せ（genre_id=nil）の場合は「その他」カテゴリと使用済みジャンルを除外
      ids_to_exclude = Genre.where(category: "その他").pluck(:id)
      ids_to_exclude += excluded_genre_ids.to_a if excluded_genre_ids.present?
      scope = scope.joins(:spot_genres).where.not(spot_genres: { genre_id: ids_to_exclude })
    end

    scope
      .left_joins(:favorite_spots)
      .group("spots.id")
      .order("COUNT(favorite_spots.id) DESC")
      .limit(limit)
      .includes(:genres)
      .map { |s| spot_to_hash(s) }
  end

  # 円内のスポットを取得するスコープ
  def spots_in_circle
    distance_sql = <<~SQL.squish
      SQRT(
        POW((lat - ?) * #{LAT_KM}, 2) +
        POW((lng - ?) * #{LNG_KM}, 2)
      )
    SQL

    Spot.where("#{distance_sql} <= ?", @center_lat, @center_lng, @radius_km)
  end

  # SpotレコードをHashに変換
  def spot_to_hash(spot)
    {
      id: spot.id,
      name: spot.name,
      address: spot.address,
      prefecture: spot.prefecture,
      city: spot.city,
      lat: spot.lat,
      lng: spot.lng,
      place_id: spot.place_id,
      genres: spot.genres.map(&:name)
    }
  end
end
