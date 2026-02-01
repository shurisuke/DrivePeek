class SuggestionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_plan
  before_action :validate_area_params, only: :suggest

  # 入力値の許容範囲
  LAT_RANGE = (-90.0..90.0).freeze
  LNG_RANGE = (-180.0..180.0).freeze
  RADIUS_RANGE = (1.0..50.0).freeze
  COUNT_RANGE = (1..10).freeze

  # おまかせ時の優先ジャンルキュー
  PRIORITY_GENRE_IDS = [
    1,   # グルメ
    16,  # 温泉・スパ
    9,   # 観光名所
    18,  # 道の駅・SA/PA
    87   # 歴史・文化
  ].freeze

  def suggest
    @result = AiAreaService.generate(**build_suggest_params)
    @result.merge!(area_data: area_data, mode: mode)
    save_and_respond
  end

  def finish
    return head(:no_content) if last_message_is_mode_select?
    @result = { type: "mode_select", message: "他にお手伝いできることはありますか？" }
    save_and_respond
  end

  private

  # --- パラメータ構築 ---
  def area_data
    @area_data ||= {
      center_lat: params[:center_lat].to_f,
      center_lng: params[:center_lng].to_f,
      radius_km: params[:radius_km].to_f
    }
  end

  def mode
    @mode ||= params[:mode] || "plan"
  end

  def build_suggest_params
    {
      plan: @plan,
      **area_data,
      slots: mode == "plan" ? fill_empty_slots(params[:slots]) : [],
      mode: mode,
      genre_id: params[:genre_id]&.to_i,
      count: params[:count]&.to_i
    }
  end

  # --- 共通処理 ---
  def save_and_respond
    @plan.suggestion_logs.create!(user: current_user, role: "assistant", content: @result.to_json)
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to edit_plan_path(@plan) }
    end
  end

  def last_message_is_mode_select?
    @plan.suggestion_logs.order(created_at: :desc).first&.response_type == "mode_select"
  end

  # --- スロット処理 ---
  def fill_empty_slots(slots)
    return [] if slots.blank?

    selected_ids = slots.map { |s| s[:genre_id] || s["genre_id"] }.compact.map(&:to_i)
    available_queue = PRIORITY_GENRE_IDS - selected_ids

    slots.map do |slot|
      genre_id = slot[:genre_id] || slot["genre_id"]
      { genre_id: genre_id.present? ? genre_id.to_i : available_queue.shift }
    end.compact
  end

  def set_plan
    @plan = current_user.plans.find(params[:plan_id])
  end

  def validate_area_params
    errors = []
    errors << "center_lat must be between -90 and 90" unless LAT_RANGE.cover?(params[:center_lat].to_f)
    errors << "center_lng must be between -180 and 180" unless LNG_RANGE.cover?(params[:center_lng].to_f)
    errors << "radius_km must be between 1 and 50" unless RADIUS_RANGE.cover?(params[:radius_km].to_f)
    errors << "count must be between 1 and 10" if params[:count].present? && !COUNT_RANGE.cover?(params[:count].to_i)

    return if errors.empty?

    render json: { errors: errors }, status: :unprocessable_entity
  end
end
