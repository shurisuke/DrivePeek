# AI を使用してスポットのジャンルを非同期で判定するジョブ
#
# GenreMapper でマッピングできなかった場合に呼び出される
#
class GenreDetectionJob < ApplicationJob
  queue_as :default

  # リトライ設定（API エラー時）
  retry_on Anthropic::Errors::APIError, wait: :polynomially_longer, attempts: 3

  def perform(spot_id)
    spot = Spot.find_by(id: spot_id)
    return if spot.nil?

    # 既にジャンルが紐付いている場合はスキップ
    return if spot.genres.exists?

    genre_ids = GenreDetector.detect(spot)
    return if genre_ids.empty?

    # SpotGenre を作成
    genre_ids.each do |genre_id|
      SpotGenre.find_or_create_by!(spot_id: spot.id, genre_id: genre_id)
    end

    Rails.logger.info "[GenreDetectionJob] Spot##{spot_id} にジャンルを紐付けました: #{genre_ids}"
  rescue ActiveRecord::RecordNotFound
    Rails.logger.warn "[GenreDetectionJob] Spot##{spot_id} が見つかりません"
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error "[GenreDetectionJob] SpotGenre 作成エラー: #{e.message}"
  end
end
