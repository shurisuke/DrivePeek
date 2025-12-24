# frozen_string_literal: true

require "test_helper"

class Plan::RouteTest < ActiveSupport::TestCase
  setup do
    @plan = plans(:one)
    @start_point = start_points(:one)
    @plan_spot = plan_spots(:one)
    @goal_point = goal_points(:one)
    @spot = spots(:one)

    # 初期状態を設定
    @start_point.update!(
      move_time: 999,
      move_distance: 999.9,
      move_cost: 999,
      polyline: "old_polyline"
    )
    @plan_spot.update!(
      move_time: 999,
      move_distance: 999.9,
      move_cost: 999,
      polyline: "old_polyline"
    )
  end

  # ----------------------------------------------------------------
  # 1) 指定された区間のみが処理対象になる
  # ----------------------------------------------------------------
  test "recalculate! processes all segments" do
    route = Plan::Route.new(@plan)
    result = route.recalculate!

    assert_equal true, result

    # start_point → plan_spot の区間が処理される
    @start_point.reload
    assert_equal 0, @start_point.move_time
    assert_equal 0.0, @start_point.move_distance
    assert_equal 0, @start_point.move_cost
    assert_nil @start_point.polyline

    # plan_spot → goal_point の区間が処理される
    @plan_spot.reload
    assert_equal 0, @plan_spot.move_time
    assert_equal 0.0, @plan_spot.move_distance
    assert_equal 0, @plan_spot.move_cost
    assert_nil @plan_spot.polyline
  end

  test "recalculate! updates start_point for first segment" do
    route = Plan::Route.new(@plan)
    route.recalculate!

    @start_point.reload

    # Phase 1: ダミー結果（0, 0, 0, nil）が保存される
    assert_equal 0, @start_point.move_time
    assert_equal 0.0, @start_point.move_distance
    assert_equal 0, @start_point.move_cost
    assert_nil @start_point.polyline
  end

  test "recalculate! updates plan_spot for subsequent segments" do
    route = Plan::Route.new(@plan)
    route.recalculate!

    @plan_spot.reload

    # Phase 1: ダミー結果（0, 0, 0, nil）が保存される
    assert_equal 0, @plan_spot.move_time
    assert_equal 0.0, @plan_spot.move_distance
    assert_equal 0, @plan_spot.move_cost
    assert_nil @plan_spot.polyline
  end

  # ----------------------------------------------------------------
  # 2) 同一区間はキャッシュされ、処理が二重に走らない
  # ----------------------------------------------------------------
  test "same segment is cached and not processed twice" do
    route = Plan::Route.new(@plan)

    # セグメントを手動で構築
    segment = {
      from_record: @start_point,
      to_record: @plan_spot,
      from_location: { lat: @start_point.lat, lng: @start_point.lng },
      to_location: { lat: @spot.lat, lng: @spot.lng },
      toll_used: false,
      segment_key: "StartPoint:#{@start_point.id}-PlanSpot:#{@plan_spot.id}-false"
    }

    # 同一セグメントを2回処理
    route.send(:process_segments, [segment, segment])

    # キャッシュに1エントリのみ
    assert_equal 1, route.segment_cache.size
  end

  test "segment_cache stores route data by segment_key" do
    route = Plan::Route.new(@plan)
    route.recalculate!

    # キャッシュにエントリが存在する
    assert route.segment_cache.any?

    # 全エントリがダミー結果
    route.segment_cache.each_value do |data|
      assert_equal 0, data[:move_time]
      assert_equal 0.0, data[:move_distance]
      assert_equal 0, data[:move_cost]
      assert_nil data[:polyline]
    end
  end

  # ----------------------------------------------------------------
  # 3) 出発側レコードに保存される（保存先ルールの確認）
  # ----------------------------------------------------------------
  test "route data is saved to departure side record (start_point)" do
    # start_point → plan_spot の区間では start_point に保存
    route = Plan::Route.new(@plan)
    route.recalculate!

    @start_point.reload
    assert_equal 0, @start_point.move_time
    assert_equal 0.0, @start_point.move_distance
  end

  test "route data is saved to departure side record (plan_spot)" do
    # plan_spot → goal_point の区間では plan_spot に保存
    route = Plan::Route.new(@plan)
    route.recalculate!

    @plan_spot.reload
    assert_equal 0, @plan_spot.move_time
    assert_equal 0.0, @plan_spot.move_distance
  end

  test "goal_point does not receive route data (arrival side only)" do
    # goal_point は到着側なので route data を持たない
    # arrival_time のみを持つ（スキーマ上 move_* カラムがない）
    route = Plan::Route.new(@plan)
    route.recalculate!

    # goal_point に move_time 等のメソッドがないことを確認
    refute @goal_point.respond_to?(:move_time)
    refute @goal_point.respond_to?(:move_distance)
  end

  # ----------------------------------------------------------------
  # 4) 複数スポットのケース
  # ----------------------------------------------------------------
  test "recalculate! handles multiple plan_spots correctly" do
    spot_two = spots(:two)
    plan_spot_two = @plan.plan_spots.create!(
      spot: spot_two,
      position: 2,
      move_time: 999,
      move_distance: 999.9,
      move_cost: 999
    )

    route = Plan::Route.new(@plan)
    route.recalculate!

    # 3区間が処理される:
    # 1. start_point → plan_spot[0]
    # 2. plan_spot[0] → plan_spot[1]
    # 3. plan_spot[1] → goal_point

    @start_point.reload
    @plan_spot.reload
    plan_spot_two.reload

    # すべてダミー結果
    assert_equal 0, @start_point.move_time
    assert_equal 0, @plan_spot.move_time
    assert_equal 0, plan_spot_two.move_time
  end

  # ----------------------------------------------------------------
  # 5) エッジケース
  # ----------------------------------------------------------------
  test "recalculate! returns false when start_point is nil" do
    @start_point.destroy!
    @plan.reload

    result = Plan::Route.new(@plan).recalculate!

    assert_equal false, result
  end

  test "recalculate! returns true when no plan_spots exist" do
    @plan_spot.destroy!
    @plan.reload

    result = Plan::Route.new(@plan).recalculate!

    assert_equal true, result
  end

  test "recalculate! succeeds when goal_point is nil" do
    @goal_point.destroy!
    @plan.reload

    result = Plan::Route.new(@plan).recalculate!

    assert_equal true, result

    # start_point → plan_spot の1区間のみ処理
    @start_point.reload
    assert_equal 0, @start_point.move_time
  end

  # ----------------------------------------------------------------
  # 6) Recalculator 経由での呼び出し
  # ----------------------------------------------------------------
  test "recalculate! is called via Plan::Recalculator with route: true" do
    result = Plan::Recalculator.new(@plan).recalculate!(route: true, schedule: false)

    assert_equal true, result

    @start_point.reload
    assert_equal 0, @start_point.move_time
  end

  test "route and schedule are executed in correct order via Recalculator" do
    # 出発時間と滞在時間を設定
    @start_point.update!(departure_time: Time.zone.parse("09:00"))
    @plan_spot.update!(stay_duration: 60)

    result = Plan::Recalculator.new(@plan).recalculate!(route: true, schedule: true)

    assert_equal true, result

    @start_point.reload
    @plan_spot.reload

    # route: ダミー結果が保存される
    assert_equal 0, @start_point.move_time

    # schedule: 時刻が計算される（move_time=0 なので即時到着）
    assert @plan_spot.arrival_time.present?
    assert_equal "09:00", @plan_spot.arrival_time.strftime("%H:%M")
    assert_equal "10:00", @plan_spot.departure_time.strftime("%H:%M") # +60分滞在
  end

  # ----------------------------------------------------------------
  # 7) recalculate_segments! のテスト
  # ----------------------------------------------------------------
  test "recalculate_segments! processes only specified segments" do
    # start_point の値を変更しておく
    @start_point.update!(move_time: 999)

    route = Plan::Route.new(@plan)

    # plan_spot → goal_point の区間のみ指定
    segment = route.send(:build_segment,
      from_record: @plan_spot,
      to_record: @goal_point,
      toll_used: false
    )

    route.recalculate_segments!([segment])

    # plan_spot は更新される
    @plan_spot.reload
    assert_equal 0, @plan_spot.move_time

    # start_point は更新されない（999のまま）
    @start_point.reload
    assert_equal 999, @start_point.move_time
  end

  test "recalculate_segments! returns true for empty segments" do
    route = Plan::Route.new(@plan)
    result = route.recalculate_segments!([])

    assert_equal true, result
  end

  # ----------------------------------------------------------------
  # 8) Phase 1: 外部APIが呼ばれていないことの確認
  # ----------------------------------------------------------------
  test "Phase 1: no external API calls are made" do
    # calculate_route がダミー結果を返すことを確認
    route = Plan::Route.new(@plan)

    segment = {
      from_record: @start_point,
      to_record: @plan_spot,
      toll_used: false
    }

    result = route.send(:calculate_route, segment)

    # ダミー結果が返される
    assert_equal Plan::Route::DUMMY_ROUTE_DATA[:move_time], result[:move_time]
    assert_equal Plan::Route::DUMMY_ROUTE_DATA[:move_distance], result[:move_distance]
    assert_equal Plan::Route::DUMMY_ROUTE_DATA[:move_cost], result[:move_cost]
    assert_nil result[:polyline]
  end
end
