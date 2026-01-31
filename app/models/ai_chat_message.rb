# AIチャットメッセージ
#
# content の形式:
#   - user: プレーンテキスト（ユーザーの入力）
#   - assistant: JSON形式
#     {
#       type: "plan" | "spots" | "answer" | "mode_select",
#       theme: "テーマ名",           # planモードのみ
#       intro: "導入文",
#       spots: [{ spot_id, name, address, lat, lng, place_id }],
#       closing: "締めの言葉",
#       area_data: { center_lat, center_lng, radius_km },
#       mode: "plan" | "spots"
#     }
#
class AiChatMessage < ApplicationRecord
  belongs_to :user
  belongs_to :plan

  validates :role, presence: true, inclusion: { in: %w[user assistant] }
  validates :content, presence: true

  # 最新N件を時系列順で取得するためのスコープ
  # 使用例: recent.limit(10) → 最新10件を古い順に並べて返す
  scope :recent, -> { order(created_at: :desc) }
  scope :chronological, -> { order(created_at: :asc) }

  # AI応答のメッセージ部分を取得
  def display_message
    return content unless assistant?

    parsed_content[:message] || ""
  end

  # AI応答のスポット情報を取得
  def display_spots
    return [] unless assistant?

    parsed_content[:spots] || []
  end

  # AI応答の締めの言葉を取得
  def display_closing
    return "" unless assistant?

    parsed_content[:closing] || ""
  end

  # AI応答の導入文を取得
  def display_intro
    return "" unless assistant?

    parsed_content[:intro] || ""
  end

  # レスポンスのタイプを取得（plan / spots / answer / conversation）
  def response_type
    return nil unless assistant?

    parsed_content[:type] || detect_type
  end

  # プランを取得（プランモード用）
  def display_plan
    return nil unless assistant?

    parsed_content[:plan] || (response_type == "plan" ? {
      theme: parsed_content[:theme],
      description: parsed_content[:description],
      spots: parsed_content[:spots] || []
    } : nil)
  end

  # エリア情報を取得（アクションボタン用）
  def area_data
    return {} unless assistant?

    parsed_content[:area_data] || {}
  end

  # 条件情報を取得（アクションボタン用）
  def condition_data
    return {} unless assistant?

    parsed_content[:condition_data] || {}
  end

  # モードを取得（plan / spots）
  def display_mode
    return "plan" unless assistant?

    parsed_content[:mode] || "plan"
  end

  def assistant?
    role == "assistant"
  end

  private

  def parsed_content
    @parsed_content ||= JSON.parse(content, symbolize_names: true)
  rescue JSON::ParserError
    { message: content, spots: [] }
  end

  # type が返されない場合のフォールバック
  def detect_type
    return "plan" if parsed_content[:theme].present?
    return "spots" if parsed_content[:intro].present? && parsed_content[:spots].present?
    "conversation"
  end
end
