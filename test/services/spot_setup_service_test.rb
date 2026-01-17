require "test_helper"

class SpotSetupServiceTest < ActiveSupport::TestCase
  setup do
    @plan = plans(:one)
    @spot_params = {
      place_id: "ChIJNewPlaceId123",
      name: "Test Restaurant",
      address: "1-2-3 Test, Tokyo",
      lat: 35.6762,
      lng: 139.6503,
      prefecture: "Tokyo",
      city: "Shibuya",
      top_types: [ "restaurant", "food", "establishment" ]
    }
  end

  test "creates spot and plan_spot successfully" do
    service = SpotSetupService.new(plan: @plan, spot_params: @spot_params)

    assert_difference [ "Spot.count", "PlanSpot.count" ], 1 do
      result = service.setup
      assert result.success?
      assert result.spot.persisted?
      assert result.plan_spot.persisted?
    end
  end

  test "does not assign genres during setup (lazy loading)" do
    service = SpotSetupService.new(plan: @plan, spot_params: @spot_params)

    result = service.setup
    assert result.success?
    # ジャンルは遅延ロードのため、setup時点では割り当てられない
    assert_equal 0, result.spot.genres.count
  end

  test "reuses existing spot when place_id matches" do
    # 別のプランを使用（既存スポットとの重複を避ける）
    other_plan = plans(:two)
    existing_spot = spots(:one)
    @spot_params[:place_id] = existing_spot.place_id

    service = SpotSetupService.new(plan: other_plan, spot_params: @spot_params)

    assert_no_difference "Spot.count" do
      assert_difference "PlanSpot.count", 1 do
        result = service.setup
        assert result.success?, "Expected success but got: #{result.error_message}"
        assert_equal existing_spot.id, result.spot.id
      end
    end
  end

  test "returns error when spot creation fails" do
    @spot_params[:name] = nil  # name is required

    service = SpotSetupService.new(plan: @plan, spot_params: @spot_params)
    result = service.setup

    assert_not result.success?
    assert result.error_message.present?
  end
end
