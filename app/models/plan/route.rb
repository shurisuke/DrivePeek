# app/models/plan/route.rb
# frozen_string_literal: true

# 責務: 経路情報（move_time / move_distance / move_cost / polyline）を計算・保存
#
# 保存先ルール（不変）:
#   - 「次の区間までの情報は出発側に保存する」
#   - start_point → 最初のplan_spot: start_points に保存
#   - plan_spot → 次のplan_spot or goal_point: plan_spots に保存
#   - goal_point は「到着側」であり、区間情報は保持しない
#
# 制約:
#   - arrival_time / departure_time には一切触らない（時刻計算は Plan::Schedule の責務）
#   - 処理完了後に Plan::Schedule を実行する
#
# Phase 1:
#   - Directions API 呼び出しは行わない（ダミー結果を返す）
#   - キャッシュ枠を用意（同一区間は処理が二重に走らない仕組み）
#
class Plan::Route
  attr_reader :plan, :segment_cache

  # ダミー結果（Phase 1）
  DUMMY_ROUTE_DATA = {
    move_time: 0,
    move_distance: 0.0,
    move_cost: 0,
    polyline: nil
  }.freeze

  def initialize(plan)
    @plan = plan
    @segment_cache = {} # キャッシュ: segment_key => route_data
  end

  # 全区間を再計算して保存
  # @return [Boolean] 成功したか
  def recalculate!
    return false unless valid_for_calculation?

    ActiveRecord::Base.transaction do
      segments = build_all_segments
      process_segments(segments)
    end

    true
  rescue ActiveRecord::RecordInvalid
    false
  end

  # 指定された区間のみ再計算して保存
  # @param segments [Array<Hash>] 再計算する区間のリスト
  # @return [Boolean] 成功したか
  def recalculate_segments!(segments)
    return true if segments.empty?

    ActiveRecord::Base.transaction do
      process_segments(segments)
    end

    true
  rescue ActiveRecord::RecordInvalid
    false
  end

  private

  # 計算可能な状態かチェック
  def valid_for_calculation?
    plan.start_point.present?
  end

  # 全区間のセグメントリストを構築
  # @return [Array<Hash>] セグメント配列
  def build_all_segments
    segments = []
    plan_spots = plan.plan_spots.includes(:spot).order(:position).to_a

    # start_point が存在し、plan_spots がある場合
    if plan_spots.any?
      # 区間1: start_point → plan_spots[0]
      segments << build_segment(
        from_record: plan.start_point,
        to_record: plan_spots.first,
        toll_used: plan.start_point.toll_used?
      )

      # 区間2〜N: plan_spots[i] → plan_spots[i+1] or goal_point
      plan_spots.each_with_index do |plan_spot, index|
        next_record = plan_spots[index + 1] || plan.goal_point
        next unless next_record

        segments << build_segment(
          from_record: plan_spot,
          to_record: next_record,
          toll_used: plan_spot.toll_used?
        )
      end
    end

    segments.compact
  end

  # セグメント情報を構築
  # @param from_record [StartPoint, PlanSpot] 出発側レコード
  # @param to_record [PlanSpot, GoalPoint] 到着側レコード
  # @param toll_used [Boolean] 有料道路使用フラグ
  # @return [Hash] セグメント情報
  def build_segment(from_record:, to_record:, toll_used:)
    from_location = extract_location(from_record)
    to_location = extract_location(to_record)

    {
      from_record: from_record,
      to_record: to_record,
      from_location: from_location,
      to_location: to_location,
      toll_used: toll_used,
      segment_key: generate_segment_key(from_record, to_record, toll_used)
    }
  end

  # レコードから位置情報を抽出
  # @param record [StartPoint, PlanSpot, GoalPoint]
  # @return [Hash] { lat:, lng: }
  def extract_location(record)
    case record
    when PlanSpot
      { lat: record.spot.lat, lng: record.spot.lng }
    else
      { lat: record.lat, lng: record.lng }
    end
  end

  # セグメントキーを生成（キャッシュ用）
  # @return [String] "from_type:from_id-to_type:to_id-toll_used"
  def generate_segment_key(from_record, to_record, toll_used)
    from_key = "#{from_record.class.name}:#{from_record.id}"
    to_key = "#{to_record.class.name}:#{to_record.id}"
    "#{from_key}-#{to_key}-#{toll_used}"
  end

  # セグメントを処理（キャッシュ利用）
  # @param segments [Array<Hash>]
  def process_segments(segments)
    segments.each do |segment|
      route_data = fetch_or_calculate_route(segment)
      save_route_data(segment[:from_record], route_data)
    end
  end

  # キャッシュから取得、なければ計算
  # @param segment [Hash]
  # @return [Hash] route_data
  def fetch_or_calculate_route(segment)
    key = segment[:segment_key]

    return segment_cache[key] if segment_cache.key?(key)

    route_data = calculate_route(segment)
    segment_cache[key] = route_data
    route_data
  end

  # 経路を計算（Phase 1: ダミー結果を返す）
  # Phase 2 で Google Directions API に置き換え
  # @param segment [Hash]
  # @return [Hash] { move_time:, move_distance:, move_cost:, polyline: }
  def calculate_route(_segment)
    # Phase 1: ダミー結果を返す（APIは呼ばない）
    DUMMY_ROUTE_DATA.dup
  end

  # 経路データを出発側レコードに保存
  # @param from_record [StartPoint, PlanSpot]
  # @param route_data [Hash]
  def save_route_data(from_record, route_data)
    from_record.update!(
      move_time: route_data[:move_time],
      move_distance: route_data[:move_distance],
      move_cost: route_data[:move_cost],
      polyline: route_data[:polyline]
    )
  end
end
