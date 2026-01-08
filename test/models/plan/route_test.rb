# frozen_string_literal: true

require "test_helper"
require "minitest/mock"

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
  # ヘルパー: DirectionsClient をスタブ
  # ----------------------------------------------------------------
  def stub_directions_client(result = nil)
    result ||= {
      move_time: 30,
      move_distance: 10.5,
      move_cost: 0,
      polyline: "encoded_polyline_string"
    }

    Plan::DirectionsClient.stub(:fetch, result) do
      yield
    end
  end

  # ----------------------------------------------------------------
  # 1) 指定された区間のみ Directions API が呼ばれる
  # ----------------------------------------------------------------
  test "recalculate! calls DirectionsClient for each segment" do
    call_count = 0
    mock_result = {
      move_time: 30,
      move_distance: 10.5,
      move_cost: 0,
      polyline: "test_polyline"
    }

    Plan::DirectionsClient.stub(:fetch, ->(*_args) { call_count += 1; mock_result }) do
      route = Plan::Route.new(@plan)
      route.recalculate!

      # 2区間: start_point→plan_spot, plan_spot→goal_point
      assert_equal 2, call_count
      assert_equal 2, route.api_call_count
    end
  end

  test "recalculate! updates all segments with API results" do
    stub_directions_client do
      route = Plan::Route.new(@plan)
      result = route.recalculate!

      assert_equal true, result

      @start_point.reload
      @plan_spot.reload

      # start_point → plan_spot の結果
      assert_equal 30, @start_point.move_time
      assert_equal 10.5, @start_point.move_distance
      assert_equal "encoded_polyline_string", @start_point.polyline

      # plan_spot → goal_point の結果
      assert_equal 30, @plan_spot.move_time
      assert_equal 10.5, @plan_spot.move_distance
      assert_equal "encoded_polyline_string", @plan_spot.polyline
    end
  end

  # ----------------------------------------------------------------
  # 2) 同一区間はキャッシュにより API が1回しか呼ばれない
  # ----------------------------------------------------------------
  test "same segment is cached and API called only once" do
    route = Plan::Route.new(@plan)

    # セグメントを手動で構築
    segment = route.send(:build_segment,
      from_record: @start_point,
      to_record: @plan_spot,
      toll_used: false
    )

    call_count = 0
    mock_result = { move_time: 30, move_distance: 10.5, move_cost: 0, polyline: "test" }

    Plan::DirectionsClient.stub(:fetch, ->(*_args) { call_count += 1; mock_result }) do
      # 同一セグメントを2回処理
      route.send(:process_segments, [ segment, segment ])

      # APIは1回しか呼ばれない
      assert_equal 1, call_count
      assert_equal 1, route.api_call_count

      # キャッシュに1エントリ
      assert_equal 1, route.segment_cache.size
    end
  end

  test "different toll_used creates different cache keys" do
    route = Plan::Route.new(@plan)

    segment_no_toll = route.send(:build_segment,
      from_record: @start_point,
      to_record: @plan_spot,
      toll_used: false
    )

    segment_with_toll = route.send(:build_segment,
      from_record: @start_point,
      to_record: @plan_spot,
      toll_used: true
    )

    # 異なるキーが生成される
    refute_equal segment_no_toll[:segment_key], segment_with_toll[:segment_key]
  end

  # ----------------------------------------------------------------
  # 3) toll_used の値が API パラメータに反映される
  # ----------------------------------------------------------------
  test "toll_used is passed to DirectionsClient" do
    received_toll_used = nil

    Plan::DirectionsClient.stub(:fetch, ->(origin:, destination:, toll_used:) {
      received_toll_used = toll_used
      { move_time: 30, move_distance: 10.5, move_cost: 0, polyline: "test" }
    }) do
      # toll_used = false のスポット
      @start_point.update!(toll_used: false)
      route = Plan::Route.new(@plan)

      segment = route.send(:build_segment,
        from_record: @start_point,
        to_record: @plan_spot,
        toll_used: @start_point.toll_used?
      )

      route.send(:calculate_route, segment)

      assert_equal false, received_toll_used
    end
  end

  test "toll_used true is passed to DirectionsClient" do
    received_toll_used = nil

    Plan::DirectionsClient.stub(:fetch, ->(origin:, destination:, toll_used:) {
      received_toll_used = toll_used
      { move_time: 30, move_distance: 10.5, move_cost: 0, polyline: "test" }
    }) do
      @start_point.update!(toll_used: true)
      route = Plan::Route.new(@plan)

      segment = route.send(:build_segment,
        from_record: @start_point,
        to_record: @plan_spot,
        toll_used: @start_point.toll_used?
      )

      route.send(:calculate_route, segment)

      assert_equal true, received_toll_used
    end
  end

  # ----------------------------------------------------------------
  # 4) 結果が出発側レコードに保存される
  # ----------------------------------------------------------------
  test "route data is saved to departure side record (start_point)" do
    stub_directions_client do
      route = Plan::Route.new(@plan)
      route.recalculate!

      @start_point.reload

      assert_equal 30, @start_point.move_time
      assert_equal 10.5, @start_point.move_distance
      assert_equal 0, @start_point.move_cost
      assert_equal "encoded_polyline_string", @start_point.polyline
    end
  end

  test "route data is saved to departure side record (plan_spot)" do
    stub_directions_client do
      route = Plan::Route.new(@plan)
      route.recalculate!

      @plan_spot.reload

      assert_equal 30, @plan_spot.move_time
      assert_equal 10.5, @plan_spot.move_distance
      assert_equal 0, @plan_spot.move_cost
      assert_equal "encoded_polyline_string", @plan_spot.polyline
    end
  end

  # ----------------------------------------------------------------
  # 5) polyline が nil ではなく保存される
  # ----------------------------------------------------------------
  test "polyline is saved to records" do
    stub_directions_client do
      route = Plan::Route.new(@plan)
      route.recalculate!

      @start_point.reload
      @plan_spot.reload

      assert_not_nil @start_point.polyline
      assert_not_nil @plan_spot.polyline
      assert_equal "encoded_polyline_string", @start_point.polyline
      assert_equal "encoded_polyline_string", @plan_spot.polyline
    end
  end

  # ----------------------------------------------------------------
  # 6) 複数スポットのケース
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

    stub_directions_client do
      route = Plan::Route.new(@plan)
      route.recalculate!

      # 3区間が処理される
      assert_equal 3, route.api_call_count

      @start_point.reload
      @plan_spot.reload
      plan_spot_two.reload

      # すべて更新される
      assert_equal 30, @start_point.move_time
      assert_equal 30, @plan_spot.move_time
      assert_equal 30, plan_spot_two.move_time
    end
  end

  # ----------------------------------------------------------------
  # 7) エッジケース
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

    stub_directions_client do
      result = Plan::Route.new(@plan).recalculate!
      assert_equal true, result
    end
  end

  test "recalculate! succeeds when goal_point is nil" do
    @goal_point.destroy!
    @plan.reload

    stub_directions_client do
      route = Plan::Route.new(@plan)
      result = route.recalculate!

      assert_equal true, result
      # start_point → plan_spot の1区間のみ
      assert_equal 1, route.api_call_count
    end
  end

  # ----------------------------------------------------------------
  # 8) Recalculator 経由での呼び出し
  # ----------------------------------------------------------------
  test "recalculate! is called via Plan::Recalculator with route: true" do
    stub_directions_client do
      result = Plan::Recalculator.new(@plan).recalculate!(route: true, schedule: false)

      assert_equal true, result

      @start_point.reload
      assert_equal 30, @start_point.move_time
    end
  end

  test "route and schedule are executed in correct order via Recalculator" do
    @start_point.update!(departure_time: Time.zone.parse("09:00"))
    @plan_spot.update!(stay_duration: 60)

    stub_directions_client do
      result = Plan::Recalculator.new(@plan).recalculate!(route: true, schedule: true)

      assert_equal true, result

      @start_point.reload
      @plan_spot.reload

      # route: API結果が保存される
      assert_equal 30, @start_point.move_time

      # schedule: 時刻が計算される
      assert @plan_spot.arrival_time.present?
      # 09:00 + 30分(move_time) = 09:30(arrival)
      assert_equal "09:30", @plan_spot.arrival_time.strftime("%H:%M")
      # 09:30 + 60分(stay) = 10:30(departure)
      assert_equal "10:30", @plan_spot.departure_time.strftime("%H:%M")
    end
  end

  # ----------------------------------------------------------------
  # 9) recalculate_segments! のテスト
  # ----------------------------------------------------------------
  test "recalculate_segments! processes only specified segments" do
    @start_point.update!(move_time: 999)

    route = Plan::Route.new(@plan)

    segment = route.send(:build_segment,
      from_record: @plan_spot,
      to_record: @goal_point,
      toll_used: false
    )

    stub_directions_client do
      route.recalculate_segments!([ segment ])

      # plan_spot は更新される
      @plan_spot.reload
      assert_equal 30, @plan_spot.move_time

      # start_point は更新されない
      @start_point.reload
      assert_equal 999, @start_point.move_time
    end
  end

  # ----------------------------------------------------------------
  # 10) API呼び出し失敗時のフォールバック
  # ----------------------------------------------------------------
  test "handles API failure gracefully with fallback values" do
    # DirectionsClient がフォールバック値を返す場合
    fallback = Plan::DirectionsClient::FALLBACK_RESULT.dup

    Plan::DirectionsClient.stub(:fetch, fallback) do
      route = Plan::Route.new(@plan)
      result = route.recalculate!

      assert_equal true, result

      @start_point.reload
      assert_equal 0, @start_point.move_time
      assert_equal 0.0, @start_point.move_distance
      assert_nil @start_point.polyline
    end
  end
end
