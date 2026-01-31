# 円内スポット検索を担当
#
# 使い方:
#   finder = AiArea::SpotFinder.new(35.6, 139.7, 10.0)
#   slot_data = finder.fetch_for_slots(slots)
#   candidates = finder.fetch_for_genre(genre, 5)
#
module AiArea
  class SpotFinder
    # 緯度1度 ≈ 111km、経度1度 ≈ 91km（日本の緯度で概算）
    LAT_KM = 111.0
    LNG_KM = 91.0

    def initialize(center_lat, center_lng, radius_km)
      @center_lat = center_lat
      @center_lng = center_lng
      @radius_km = radius_km
    end

    # プランモード用: 各スロットに対して候補スポットを取得（人気順10件）
    # @param slots [Array<Hash>] [{ genre_id: 5 }, ...]
    # @return [Array<Hash>] [{ genre_name:, candidates: [spot_hash, ...] }, ...]
    def fetch_for_slots(slots)
      slots.filter_map do |slot|
        genre_id = slot[:genre_id] || slot["genre_id"]
        genre = Genre.find_by(id: genre_id)
        next unless genre

        candidates = fetch_candidates_by_genre(genre.id, 10)
        next if candidates.empty?

        { genre_name: genre.name, candidates: candidates }
      end
    end

    # スポットモード用: 人気スポットを取得（人気順N件）
    # @param genre [Genre] 対象ジャンル
    # @param count [Integer] 取得件数
    # @return [Array<Hash>] [spot_hash, ...]
    def fetch_for_genre(genre, count)
      fetch_candidates_by_genre(genre.id, count)
    end

    private

    # 指定ジャンルの候補スポットを人気順で取得
    def fetch_candidates_by_genre(genre_id, limit)
      # まず円内+ジャンルでスポットIDを取得（DISTINCTを回避）
      candidate_ids = spots_in_circle
        .filter_by_genres([ genre_id ])
        .pluck(:id)

      return [] if candidate_ids.empty?

      # お気に入り数上位N件を候補として取得
      top_spot_ids = Spot
        .where(id: candidate_ids)
        .left_joins(:like_spots)
        .group(:id)
        .order("COUNT(like_spots.id) DESC")
        .limit(limit)
        .pluck(:id)

      Spot.includes(:genres).where(id: top_spot_ids).map { |s| spot_to_hash(s) }
    end

    # 円内のスポットを取得するスコープ
    def spots_in_circle
      distance_sql = <<~SQL.squish
        SQRT(
          POW((lat - ?) * #{LAT_KM}, 2) +
          POW((lng - ?) * #{LNG_KM}, 2)
        )
      SQL

      Spot
        .where("#{distance_sql} <= ?", @center_lat, @center_lng, @radius_km)
        .includes(:genres)
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
end
