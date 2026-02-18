# frozen_string_literal: true

module SuggestionsHelper
  # スポット関連データを一括プリロード（N+1回避）
  # @param spot_ids [Array<Integer>] スポットIDの配列
  # @param user [User, nil] ログインユーザー
  # @return [Hash] { preloaded_spots: Hash, user_favorite_spots: Hash }
  def preload_spot_data(spot_ids, user)
    return { preloaded_spots: {}, user_favorite_spots: {} } if spot_ids.blank?

    preloaded_spots = Spot.where(id: spot_ids)
                          .includes(:genres)
                          .left_joins(:favorite_spots, :spot_comments)
                          .select("spots.*, COUNT(DISTINCT favorite_spots.id) AS favorites_count, COUNT(DISTINCT spot_comments.id) AS comments_count")
                          .group("spots.id")
                          .index_by(&:id)

    user_favorite_spots = if user
                            user.favorite_spots.where(spot_id: spot_ids).index_by(&:spot_id)
    else
                            {}
    end

    { preloaded_spots: preloaded_spots, user_favorite_spots: user_favorite_spots }
  end
end
