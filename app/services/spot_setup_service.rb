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
end
