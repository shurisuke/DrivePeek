class SpotSetupService
  attr_reader :plan, :user, :spot_params

  Result = Struct.new(:success?, :spot, :plan_spot, :user_spot, :error_message, :errors, keyword_init: true)

  def initialize(plan:, user:, spot_params:)
    @plan = plan
    @user = user
    @spot_params = spot_params.to_h.with_indifferent_access
  end

  # トランザクション内で Spot / PlanSpot / UserSpot を一貫して作成
  def setup
    ActiveRecord::Base.transaction do
      spot = find_or_create_spot
      plan_spot = create_plan_spot(spot)
      user_spot = find_or_create_user_spot(spot)

      # ジャンル判定（トランザクション外で実行）
      assign_genres_later(spot)

      Result.new(success?: true, spot: spot, plan_spot: plan_spot, user_spot: user_spot)
    end
  rescue ActiveRecord::RecordInvalid => e
    Result.new(success?: false, error_message: e.message, errors: e.record.errors.full_messages)
  rescue StandardError => e
    Rails.logger.error "[SpotSetupService] #{e.class}: #{e.message}"
    Result.new(success?: false, error_message: "スポットの追加に失敗しました", errors: [])
  end

  private

  def find_or_create_spot
    spot = Spot.find_or_initialize_by(place_id: spot_params[:place_id])
    spot.apply_google_payload(spot_params)
    spot.save!
    spot
  end

  def create_plan_spot(spot)
    # acts_as_list が末尾に自動追加
    plan.plan_spots.create!(spot: spot)
  end

  def find_or_create_user_spot(spot)
    UserSpot.find_or_create_by!(user: user, spot: spot)
  end

  # ジャンル判定を実行
  # - 既にジャンルが紐付いている場合はスキップ
  # - GenreMapper でマッピング可能なら同期で即反映
  # - マッピング不可なら AI ジョブをキュー
  def assign_genres_later(spot)
    return if spot.genres.exists?

    top_types = Array(spot_params[:top_types])
    genre_ids = GenreMapper.map(top_types)

    if genre_ids.present?
      # マッピング成功: 同期で SpotGenre を作成
      genre_ids.each do |genre_id|
        SpotGenre.find_or_create_by!(spot_id: spot.id, genre_id: genre_id)
      end
      Rails.logger.info "[SpotSetupService] Spot##{spot.id} にジャンルをマッピング: #{genre_ids}"
    else
      # マッピング失敗: AI ジョブをキュー
      GenreDetectionJob.perform_later(spot.id)
      Rails.logger.info "[SpotSetupService] Spot##{spot.id} のジャンル判定を AI ジョブにキュー"
    end
  rescue StandardError => e
    # ジャンル判定の失敗はスポット追加自体には影響させない
    Rails.logger.error "[SpotSetupService] ジャンル判定エラー: #{e.message}"
  end
end
