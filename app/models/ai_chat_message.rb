# AIチャットメッセージ
#
# content の形式:
#   - user: プレーンテキスト（ユーザーの入力）
#   - assistant: JSON形式
#     {
#       type: "plan" | "spots" | "answer" | "conversation",
#       theme: "テーマ名",           # planモードのみ
#       description: "説明",         # planモードのみ
#       intro: "導入文",             # spotsモードのみ
#       spots: [{ spot_id, name, address, description, lat, lng, place_id }],
#       closing: "締めの言葉"
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

  # スポットに関する質問に回答し、メッセージを保存して結果を返す
  # @param plan [Plan] 現在編集中のプラン
  # @param user [User] ユーザー
  # @param message [String] ユーザーからの質問
  # @return [Hash] { result: Hash, message: AiChatMessage }
  def self.chat(plan:, user:, message:)
    # ユーザーメッセージを保存
    plan.ai_chat_messages.create!(user: user, role: "user", content: message)

    # スポットに関する質問に回答（answerモード）
    result = AiChatService.answer(message, plan: plan)

    ai_message = plan.ai_chat_messages.create!(user: user, role: "assistant", content: result.to_json)
    { result: result, message: ai_message }
  end

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
