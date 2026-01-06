# frozen_string_literal: true

require "test_helper"

class PlanSpots::StayDurationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @plan = plans(:one)
    @start_point = start_points(:one)
    @plan_spot = plan_spots(:one)
    @goal_point = goal_points(:one)

    sign_in @user

    # 初期状態を設定
    # move_time の保存先ルール:
    #   - start_point.move_time = start → first_spot
    #   - plan_spot.move_time = spot → next (goal)
    @start_point.update!(departure_time: Time.zone.parse("09:00"), move_time: 30)
    @plan_spot.update!(
      move_time: 0,  # spot → goal: 0分
      stay_duration: 60,
      arrival_time: Time.zone.parse("09:30"),
      departure_time: Time.zone.parse("10:30")
    )
    @goal_point.update!(arrival_time: Time.zone.parse("10:30"))
  end

  test "update stay_duration triggers schedule recalculation" do
    # 滞在時間を60分から120分に変更
    patch stay_duration_api_plan_plan_spot_path(@plan, @plan_spot), params: {
      stay_duration: 120
    }, as: :json

    assert_response :success

    @plan_spot.reload
    @goal_point.reload

    # stay_duration が 120分に変更されている
    assert_equal 120, @plan_spot.stay_duration
    # departure_time: arrival_time + stay_duration = 09:30 + 120分 = 11:30
    assert_equal "11:30", @plan_spot.departure_time.strftime("%H:%M")
    # goal arrival_time: plan_spot departure_time
    assert_equal "11:30", @goal_point.arrival_time.strftime("%H:%M")
  end

  test "update stay_duration to shorter value recalculates times" do
    # 滞在時間を60分から30分に変更
    patch stay_duration_api_plan_plan_spot_path(@plan, @plan_spot), params: {
      stay_duration: 30
    }, as: :json

    assert_response :success

    @plan_spot.reload
    @goal_point.reload

    assert_equal 30, @plan_spot.stay_duration
    # departure_time: arrival_time + stay_duration = 09:30 + 30分 = 10:00
    assert_equal "10:00", @plan_spot.departure_time.strftime("%H:%M")
    # goal arrival_time: plan_spot departure_time
    assert_equal "10:00", @goal_point.arrival_time.strftime("%H:%M")
  end

  test "update stay_duration to empty value clears duration" do
    patch stay_duration_api_plan_plan_spot_path(@plan, @plan_spot), params: {
      stay_duration: ""
    }, as: :json

    assert_response :success

    @plan_spot.reload

    assert_nil @plan_spot.stay_duration
  end

  test "update returns json response with plan_spot_id and stay_duration" do
    patch stay_duration_api_plan_plan_spot_path(@plan, @plan_spot), params: {
      stay_duration: 90
    }, as: :json

    assert_response :success

    json = JSON.parse(response.body)
    assert_equal @plan_spot.id, json["plan_spot_id"]
    assert_equal 90, json["stay_duration"]
  end
end
