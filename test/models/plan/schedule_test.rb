# frozen_string_literal: true

require "test_helper"

class Plan::ScheduleTest < ActiveSupport::TestCase
  setup do
    @plan = plans(:one)
    @start_point = start_points(:one)
    @plan_spot = plan_spots(:one)
    @goal_point = goal_points(:one)
  end

  test "recalculate! returns false when start_point is nil" do
    user = users(:two)
    plan_without_start = Plan.create!(user: user, title: "No Start")

    result = Plan::Schedule.new(plan_without_start).recalculate!
    assert_equal false, result
  end

  test "recalculate! returns false when departure_time is nil" do
    @start_point.update_column(:departure_time, nil)

    result = Plan::Schedule.new(@plan).recalculate!
    assert_equal false, result
  end

  test "recalculate! calculates arrival/departure times for single spot" do
    # Setup: departure_time = 09:00, move_time = 30min, stay_duration = 60min
    @start_point.update!(departure_time: Time.zone.parse("09:00"))
    @plan_spot.update!(move_time: 30, stay_duration: 60)

    result = Plan::Schedule.new(@plan).recalculate!

    assert_equal true, result

    @plan_spot.reload
    @goal_point.reload

    # arrival_time = 09:00 + 30min = 09:30
    assert_equal "09:30", @plan_spot.arrival_time.strftime("%H:%M")
    # departure_time = 09:30 + 60min = 10:30
    assert_equal "10:30", @plan_spot.departure_time.strftime("%H:%M")
    # goal arrival = 10:30
    assert_equal "10:30", @goal_point.arrival_time.strftime("%H:%M")
  end

  test "recalculate! calculates times for multiple spots in order" do
    # 新しいスポットを追加
    spot2 = Spot.create!(
      name: "Spot 2",
      address: "Address 2",
      lat: 35.1,
      lng: 139.1,
      place_id: "unique_place_id_for_test_multi"
    )

    plan_spot2 = @plan.plan_spots.create!(
      spot: spot2,
      position: 2,
      move_time: 45,
      stay_duration: 90
    )

    # departure_time = 09:00
    # spot1: move_time = 30min, stay_duration = 60min
    # spot2: move_time = 45min, stay_duration = 90min
    @start_point.update!(departure_time: Time.zone.parse("09:00"))
    @plan_spot.update!(move_time: 30, stay_duration: 60)

    result = Plan::Schedule.new(@plan).recalculate!

    assert_equal true, result

    @plan_spot.reload
    plan_spot2.reload
    @goal_point.reload

    # spot1: arrival = 09:00 + 30 = 09:30, departure = 09:30 + 60 = 10:30
    assert_equal "09:30", @plan_spot.arrival_time.strftime("%H:%M")
    assert_equal "10:30", @plan_spot.departure_time.strftime("%H:%M")

    # spot2: arrival = 10:30 + 45 = 11:15, departure = 11:15 + 90 = 12:45
    assert_equal "11:15", plan_spot2.arrival_time.strftime("%H:%M")
    assert_equal "12:45", plan_spot2.departure_time.strftime("%H:%M")

    # goal: arrival = 12:45
    assert_equal "12:45", @goal_point.arrival_time.strftime("%H:%M")
  end

  test "recalculate! handles departure_time change" do
    @start_point.update!(departure_time: Time.zone.parse("09:00"))
    @plan_spot.update!(move_time: 30, stay_duration: 60)

    # Initial calculation
    Plan::Schedule.new(@plan).recalculate!
    @plan_spot.reload
    assert_equal "09:30", @plan_spot.arrival_time.strftime("%H:%M")

    # Change departure_time to 10:00
    @start_point.update!(departure_time: Time.zone.parse("10:00"))
    # start_point を更新したので plan をリロードして関連を更新
    @plan.reload
    Plan::Schedule.new(@plan).recalculate!

    @plan_spot.reload
    # arrival_time = 10:00 + 30 = 10:30
    assert_equal "10:30", @plan_spot.arrival_time.strftime("%H:%M")
    # departure_time = 10:30 + 60 = 11:30
    assert_equal "11:30", @plan_spot.departure_time.strftime("%H:%M")
  end

  test "recalculate! handles stay_duration change" do
    spot2 = Spot.create!(
      name: "Spot 2",
      address: "Address 2",
      lat: 35.1,
      lng: 139.1,
      place_id: "unique_place_id_for_stay_test"
    )

    plan_spot2 = @plan.plan_spots.create!(
      spot: spot2,
      position: 2,
      move_time: 30,
      stay_duration: 60
    )

    @start_point.update!(departure_time: Time.zone.parse("09:00"))
    @plan_spot.update!(move_time: 30, stay_duration: 60)

    # Initial calculation
    Plan::Schedule.new(@plan).recalculate!

    @plan_spot.reload
    plan_spot2.reload

    # spot1: departure = 09:30 + 60 = 10:30
    assert_equal "10:30", @plan_spot.departure_time.strftime("%H:%M")
    # spot2: arrival = 10:30 + 30 = 11:00
    assert_equal "11:00", plan_spot2.arrival_time.strftime("%H:%M")

    # Change stay_duration from 60 to 120
    @plan_spot.update!(stay_duration: 120)
    Plan::Schedule.new(@plan).recalculate!

    @plan_spot.reload
    plan_spot2.reload

    # spot1: departure = 09:30 + 120 = 11:30
    assert_equal "11:30", @plan_spot.departure_time.strftime("%H:%M")
    # spot2: arrival = 11:30 + 30 = 12:00
    assert_equal "12:00", plan_spot2.arrival_time.strftime("%H:%M")
  end

  test "recalculate! handles zero move_time and nil stay_duration" do
    @start_point.update!(departure_time: Time.zone.parse("09:00"))
    # move_time は NOT NULL 制約があるため 0 を使用、stay_duration は nullable
    @plan_spot.update!(move_time: 0, stay_duration: nil)

    result = Plan::Schedule.new(@plan).recalculate!

    assert_equal true, result

    @plan_spot.reload
    # arrival_time = 09:00 + 0 = 09:00
    assert_equal "09:00", @plan_spot.arrival_time.strftime("%H:%M")
    # departure_time = 09:00 + 0 = 09:00
    assert_equal "09:00", @plan_spot.departure_time.strftime("%H:%M")
  end

  test "recalculate! wraps time past midnight" do
    @start_point.update!(departure_time: Time.zone.parse("23:00"))
    @plan_spot.update!(move_time: 90, stay_duration: 60)

    result = Plan::Schedule.new(@plan).recalculate!

    assert_equal true, result

    @plan_spot.reload
    # arrival_time = 23:00 + 90min = 00:30 (翌日)
    assert_equal "00:30", @plan_spot.arrival_time.strftime("%H:%M")
    # departure_time = 00:30 + 60min = 01:30
    assert_equal "01:30", @plan_spot.departure_time.strftime("%H:%M")
  end

  test "recalculate! works without goal_point" do
    user = users(:two)
    plan_no_goal = Plan.create!(user: user, title: "No Goal")

    plan_no_goal.create_start_point!(
      lat: 35.0,
      lng: 139.0,
      address: "Start Address",
      departure_time: Time.zone.parse("09:00")
    )

    spot = Spot.create!(
      name: "Spot",
      address: "Address",
      lat: 35.0,
      lng: 139.0,
      place_id: "unique_place_id_for_no_goal"
    )

    plan_spot = plan_no_goal.plan_spots.create!(
      spot: spot,
      position: 1,
      move_time: 30,
      stay_duration: 60
    )

    # No goal_point
    assert_nil plan_no_goal.goal_point

    result = Plan::Schedule.new(plan_no_goal).recalculate!

    assert_equal true, result

    plan_spot.reload
    assert_equal "09:30", plan_spot.arrival_time.strftime("%H:%M")
    assert_equal "10:30", plan_spot.departure_time.strftime("%H:%M")
  end
end
