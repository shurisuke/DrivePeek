# AI を使用してスポットのジャンルを非同期で判定・補完するジョブ
#
# GenreMapper でマッピングした結果が2個未満の場合に呼び出される
#
class GenreDetectionJob < ApplicationJob
  queue_as :default

  # リトライ設定（API エラー時）
  retry_on Anthropic::Errors::APIError, wait: :polynomially_longer, attempts: 3

  # @param spot_id [Integer] スポットID
  # @param current_count [Integer] 既にマッピングされたジャンル数
  def perform(spot_id, current_count = 0)
    spot = Spot.find_by(id: spot_id)
    return if spot.nil?

    # 既に2個以上ある場合はスキップ
    existing_ids = spot.genre_ids
    return if existing_ids.size >= 2

    # 不足分を AI で判定
    needed_count = 2 - existing_ids.size
    genre_ids = GenreDetector.detect(spot, count: needed_count, exclude_ids: existing_ids)
    return if genre_ids.empty?

    # SpotGenre を作成
    genre_ids.each do |genre_id|
      SpotGenre.find_or_create_by!(spot_id: spot.id, genre_id: genre_id)
    end

    Rails.logger.info "[GenreDetectionJob] Spot##{spot_id} にジャンルを補完: #{genre_ids}"
  rescue ActiveRecord::RecordNotFound
    Rails.logger.warn "[GenreDetectionJob] Spot##{spot_id} が見つかりません"
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error "[GenreDetectionJob] SpotGenre 作成エラー: #{e.message}"
  end
end
