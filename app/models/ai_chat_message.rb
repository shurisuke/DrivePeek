class AiChatMessage < ApplicationRecord
  belongs_to :user
  belongs_to :plan

  validates :role, presence: true, inclusion: { in: %w[user assistant] }
  validates :content, presence: true

  # 最新N件を時系列順で取得するためのスコープ
  # 使用例: recent.limit(10) → 最新10件を古い順に並べて返す
  scope :recent, -> { order(created_at: :desc) }
  scope :chronological, -> { order(created_at: :asc) }

  # AIとチャットし、メッセージを保存して結果を返す
  def self.chat(plan:, user:, message:, mode:)
    plan.ai_chat_messages.create!(user: user, role: "user", content: message)

    history = plan.ai_chat_messages.recent.limit(5).reverse
    result = AiChatService.chat(message, plan: plan, history: history, mode: mode)

    plan.ai_chat_messages.create!(user: user, role: "assistant", content: result.to_json)
    result
  end

  # AI応答のメッセージ部分を取得
  # assistantの場合はJSONをパースして取り出す
  def display_message
    return content unless assistant?

    parsed_content[:message] || ""
  end

  # AI応答のスポット情報を取得
  def display_spots
    return [] unless assistant?

    parsed_content[:spots] || []
  end

  # AI応答の締めの言葉を取得（スポットモード用）
  def display_closing
    return "" unless assistant?

    parsed_content[:closing] || ""
  end

  # AI応答の導入文を取得（スポットモード用）
  def display_intro
    return "" unless assistant?

    parsed_content[:intro] || ""
  end

  # スポットモードかどうか（spotsにdescriptionがあるか）
  def spot_mode?
    return false unless assistant?

    spots = display_spots
    spots.present? && spots.first.is_a?(Hash) && spots.first[:description].present?
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
end
