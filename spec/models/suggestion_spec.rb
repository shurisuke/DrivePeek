# frozen_string_literal: true

require "rails_helper"

RSpec.describe Suggestion, type: :model do
  let(:user) { create(:user) }
  let(:plan) { create(:plan, user: user) }

  describe "バリデーション" do
    it "有効なデータで作成できる" do
      log = build(:suggestion, user: user, plan: plan, role: "user", content: "テスト")
      expect(log).to be_valid
    end

    it "roleがuserまたはassistantでないと無効" do
      log = build(:suggestion, user: user, plan: plan, role: "invalid", content: "テスト")
      expect(log).not_to be_valid
    end

    it "contentが空だと無効" do
      log = build(:suggestion, user: user, plan: plan, role: "user", content: "")
      expect(log).not_to be_valid
    end
  end

  describe "スコープ" do
    before do
      create(:suggestion, user: user, plan: plan, role: "user", content: "古い", created_at: 1.hour.ago)
      create(:suggestion, user: user, plan: plan, role: "assistant", content: "{}", created_at: 30.minutes.ago)
      create(:suggestion, user: user, plan: plan, role: "user", content: "新しい", created_at: Time.current)
    end

    it "recentは新しい順にソート" do
      logs = plan.suggestions.recent
      expect(logs.first.content).to eq("新しい")
    end

    it "chronologicalは古い順にソート" do
      logs = plan.suggestions.chronological
      expect(logs.first.content).to eq("古い")
    end
  end

  describe "#assistant?" do
    it "roleがassistantならtrue" do
      log = build(:suggestion, role: "assistant", content: "{}")
      expect(log.assistant?).to be true
    end

    it "roleがuserならfalse" do
      log = build(:suggestion, role: "user", content: "テスト")
      expect(log.assistant?).to be false
    end
  end

  describe "userロールの場合" do
    let(:log) { create(:suggestion, user: user, plan: plan, role: "user", content: "ユーザーメッセージ") }

    it "#display_messageはcontentをそのまま返す" do
      expect(log.display_message).to eq("ユーザーメッセージ")
    end

    it "#display_spotsは空配列を返す" do
      expect(log.display_spots).to eq([])
    end

    it "#display_closingは空文字を返す" do
      expect(log.display_closing).to eq("")
    end

    it "#display_introは空文字を返す" do
      expect(log.display_intro).to eq("")
    end

    it "#response_typeはnilを返す" do
      expect(log.response_type).to be_nil
    end

    it "#display_planはnilを返す" do
      expect(log.display_plan).to be_nil
    end

    it "#area_dataは空ハッシュを返す" do
      expect(log.area_data).to eq({})
    end

    it "#condition_dataは空ハッシュを返す" do
      expect(log.condition_data).to eq({})
    end

    it "#display_modeはplanを返す" do
      expect(log.display_mode).to eq("plan")
    end
  end

  describe "assistantロールの場合" do
    context "有効なJSONコンテンツ" do
      let(:content) do
        {
          type: "spots",
          message: "おすすめスポットです",
          intro: "こんにちは",
          closing: "いかがでしょうか",
          spots: [ { spot_id: 1, name: "テストスポット" } ],
          area_data: { center_lat: 35.0, center_lng: 139.0, radius_km: 5 },
          condition_data: { genre_id: 1 },
          mode: "spots"
        }.to_json
      end

      let(:log) { create(:suggestion, user: user, plan: plan, role: "assistant", content: content) }

      it "#display_messageはmessageを返す" do
        expect(log.display_message).to eq("おすすめスポットです")
      end

      it "#display_spotsはspotsを返す" do
        expect(log.display_spots).to eq([ { spot_id: 1, name: "テストスポット" } ])
      end

      it "#display_closingはclosingを返す" do
        expect(log.display_closing).to eq("いかがでしょうか")
      end

      it "#display_introはintroを返す" do
        expect(log.display_intro).to eq("こんにちは")
      end

      it "#response_typeはtypeを返す" do
        expect(log.response_type).to eq("spots")
      end

      it "#area_dataはエリア情報を返す" do
        expect(log.area_data).to eq({ center_lat: 35.0, center_lng: 139.0, radius_km: 5 })
      end

      it "#condition_dataは条件情報を返す" do
        expect(log.condition_data).to eq({ genre_id: 1 })
      end

      it "#display_modeはmodeを返す" do
        expect(log.display_mode).to eq("spots")
      end
    end

    context "planモードのコンテンツ" do
      let(:content) do
        {
          type: "plan",
          theme: "海沿いドライブ",
          description: "海を楽しむプラン",
          spots: [ { spot_id: 1, name: "海岸" } ]
        }.to_json
      end

      let(:log) { create(:suggestion, user: user, plan: plan, role: "assistant", content: content) }

      it "#display_planはプラン情報を返す" do
        expect(log.display_plan).to eq({
          theme: "海沿いドライブ",
          description: "海を楽しむプラン",
          spots: [ { spot_id: 1, name: "海岸" } ]
        })
      end
    end

    context "typeがない場合のフォールバック" do
      it "themeがあればplanと判定" do
        content = { theme: "テーマ" }.to_json
        log = create(:suggestion, user: user, plan: plan, role: "assistant", content: content)
        expect(log.response_type).to eq("plan")
      end

      it "introとspotsがあればspotsと判定" do
        content = { intro: "導入", spots: [ { id: 1 } ] }.to_json
        log = create(:suggestion, user: user, plan: plan, role: "assistant", content: content)
        expect(log.response_type).to eq("spots")
      end

      it "どちらもなければconversationと判定" do
        content = { message: "普通の会話" }.to_json
        log = create(:suggestion, user: user, plan: plan, role: "assistant", content: content)
        expect(log.response_type).to eq("conversation")
      end
    end

    context "不正なJSON" do
      let(:log) { create(:suggestion, user: user, plan: plan, role: "assistant", content: "不正なJSON{{{") }

      it "#display_messageはcontentをそのまま返す" do
        expect(log.display_message).to eq("不正なJSON{{{")
      end

      it "#display_spotsは空配列を返す" do
        expect(log.display_spots).to eq([])
      end
    end
  end
end
