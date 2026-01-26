# frozen_string_literal: true

FactoryBot.define do
  factory :ai_chat_message do
    association :user
    association :plan
    role { "user" }
    content { "大洗でドライブプランを考えてください" }

    trait :user_message do
      role { "user" }
      content { "大洗でドライブプランを考えてください" }
    end

    trait :assistant_plan do
      role { "assistant" }
      content do
        {
          type: "plan",
          theme: "大洗海岸ドライブ",
          description: "茨城県大洗町の海沿いを巡るドライブプランです。",
          spots: [
            { spot_id: 1, name: "アクアワールド大洗", description: "海の生き物を楽しめる水族館" }
          ],
          closing: "楽しいドライブを！"
        }.to_json
      end
    end

    trait :assistant_spots do
      role { "assistant" }
      content do
        {
          type: "spots",
          intro: "おすすめのスポットをご紹介します。",
          spots: [
            { spot_id: 1, name: "テストスポット", description: "説明文" }
          ],
          closing: "いかがでしょうか？"
        }.to_json
      end
    end

    trait :assistant_conversation do
      role { "assistant" }
      content do
        {
          type: "conversation",
          message: "どのエリアでドライブしたいですか？"
        }.to_json
      end
    end
  end
end
