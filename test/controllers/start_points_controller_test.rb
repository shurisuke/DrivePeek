# frozen_string_literal: true

require "test_helper"
require "minitest/mock"

class StartPointsControllerTest < ActionDispatch::IntegrationTest
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
    @plan_spot.update!(move_time: 0, stay_duration: 60)  # spot → goal: 0分
  end

  test "update departure_time triggers schedule recalculation" do
    # 出発時間を10:00に変更
    patch plan_start_point_path(@plan), params: {
      start_point: { departure_time: "10:00" }
    }, as: :json

    assert_response :success

    # 時刻が再計算されていることを確認
    @plan_spot.reload
    @goal_point.reload

    # arrival_time: departure_time + move_time = 10:00 + 30分 = 10:30
    assert_equal "10:30", @plan_spot.arrival_time.strftime("%H:%M")
    # departure_time: arrival_time + stay_duration = 10:30 + 60分 = 11:30
    assert_equal "11:30", @plan_spot.departure_time.strftime("%H:%M")
    # goal arrival_time: plan_spot departure_time
    assert_equal "11:30", @goal_point.arrival_time.strftime("%H:%M")
  end

  test "update toll_used triggers route and schedule recalculation" do
    # 初期時刻を設定
    @plan_spot.update!(
      arrival_time: Time.zone.parse("09:30"),
      departure_time: Time.zone.parse("10:30")
    )

    # toll_used を更新 → 経路が変わるため route + schedule 再計算
    @start_point.update!(lat: 35.6580, lng: 139.7016)

    # DirectionsClient をスタブして経路情報を返す
    stub_response = {
      move_time: 20,
      move_distance: 15.0,
      move_cost: 500,
      polyline: "test"
    }
    Plan::DirectionsClient.stub(:fetch, ->(*_args) { stub_response }) do
      patch plan_start_point_path(@plan), params: {
        start_point: { toll_used: true }
      }, as: :json
    end

    assert_response :success

    @start_point.reload
    @plan_spot.reload

    # 経路再計算により start_point.move_time が更新され、時刻も再計算される
    # ✅ Route は from_record（start_point）に保存
    assert_equal 20, @start_point.move_time
    # departure_time(09:00) + move_time(20分) = arrival_time(09:20)
    assert_equal "09:20", @plan_spot.arrival_time.strftime("%H:%M")
  end

  test "update returns success json response" do
    patch plan_start_point_path(@plan), params: {
      start_point: { departure_time: "08:00" }
    }, as: :json

    assert_response :success

    json = JSON.parse(response.body)
    assert_equal true, json["ok"]
    assert json["start_point"]["departure_time"].present?
  end
end
