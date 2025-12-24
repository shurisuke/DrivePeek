# frozen_string_literal: true

require "test_helper"
require "minitest/mock"

class Plan::RecalculatorTest < ActiveSupport::TestCase
  setup do
    @plan = plans(:one)
    @start_point = start_points(:one)
    @plan_spot = plan_spots(:one)
    @goal_point = goal_points(:one)

    # 初期状態を設定
    # move_time の保存先ルール:
    #   - start_point.move_time = start → first_spot
    #   - plan_spot.move_time = spot → next (goal)
    @start_point.update!(departure_time: Time.zone.parse("09:00"), move_time: 30)
    @plan_spot.update!(move_time: 0, stay_duration: 60)  # spot → goal: 0分
  end

  # ----------------------------------------------------------------
  # ヘルパー: DirectionsClient をスタブ（Phase 2 対応）
  # ----------------------------------------------------------------
  def stub_directions_client(result = nil)
    result ||= {
      move_time: 0,
      move_distance: 0.0,
      move_cost: 0,
      polyline: nil
    }

    Plan::DirectionsClient.stub(:fetch, result) do
      yield
    end
  end

  test "recalculate! with schedule: true recalculates times" do
    result = Plan::Recalculator.new(@plan).recalculate!(schedule: true)

    assert_equal true, result

    @plan_spot.reload
    @goal_point.reload

    assert_equal "09:30", @plan_spot.arrival_time.strftime("%H:%M")
    assert_equal "10:30", @plan_spot.departure_time.strftime("%H:%M")
    assert_equal "10:30", @goal_point.arrival_time.strftime("%H:%M")
  end

  test "recalculate! with schedule: false does not recalculate times" do
    # 初期時刻を設定
    @plan_spot.update!(arrival_time: Time.zone.parse("08:00"), departure_time: Time.zone.parse("08:30"))

    result = Plan::Recalculator.new(@plan).recalculate!(schedule: false)

    assert_equal true, result

    @plan_spot.reload
    # 時刻は変更されていない
    assert_equal "08:00", @plan_spot.arrival_time.strftime("%H:%M")
    assert_equal "08:30", @plan_spot.departure_time.strftime("%H:%M")
  end

  test "recalculate! with route: true calls Route.recalculate!" do
    stub_directions_client do
      result = Plan::Recalculator.new(@plan).recalculate!(route: true, schedule: true)

      assert_equal true, result

      # Route により move_time=0 になり、Schedule も計算される
      @plan_spot.reload
      # 09:00 + 0分(move_time) = 09:00(arrival) + 60分(stay) = 10:00(departure)
      assert_equal "09:00", @plan_spot.arrival_time.strftime("%H:%M")
    end
  end

  test "recalculate! returns true by default (schedule only)" do
    result = Plan::Recalculator.new(@plan).recalculate!

    assert_equal true, result

    @plan_spot.reload
    assert_equal "09:30", @plan_spot.arrival_time.strftime("%H:%M")
  end

  test "recalculate! executes route before schedule" do
    stub_directions_client do
      # route → schedule の順序を確認
      result = Plan::Recalculator.new(@plan).recalculate!(route: true, schedule: true)

      assert_equal true, result

      # route が先に実行され（move_time=0）、schedule が後に実行される
      @plan_spot.reload
      # 09:00 + 0分(move_time) = 09:00(arrival) + 60分(stay) = 10:00(departure)
      assert_equal "09:00", @plan_spot.arrival_time.strftime("%H:%M")
      assert_equal "10:00", @plan_spot.departure_time.strftime("%H:%M")
    end
  end

  test "recalculate! returns true when departure_time is nil (schedule skipped)" do
    # departure_time を nil にすると schedule はスキップされる（成功扱い）
    # ※ route の計算結果をロールバックさせないための仕様
    @start_point.update_column(:departure_time, nil)

    result = Plan::Recalculator.new(@plan).recalculate!(schedule: true)

    assert_equal true, result
  end

  test "recalculate! with both route and schedule false returns true" do
    result = Plan::Recalculator.new(@plan).recalculate!(route: false, schedule: false)

    assert_equal true, result
  end
end
