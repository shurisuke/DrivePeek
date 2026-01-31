# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::AiArea", type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:plan) { create(:plan, user: user) }

  let(:area_params) do
    {
      plan_id: plan.id,
      center_lat: 35.6762,
      center_lng: 139.6503,
      radius_km: 10.0
    }
  end

  before do
    stub_google_geocoding_api
    stub_google_directions_api
  end

  describe "POST /api/ai_area/suggest" do
    context "プランモード" do
      let!(:genre_gourmet) { create(:genre, name: "グルメ", slug: "gourmet") }
      let!(:genre_onsen) { create(:genre, name: "温泉", slug: "onsen") }
      let!(:spot) do
        create(:spot, lat: 35.6770, lng: 139.6510, name: "テストスポット").tap do |s|
          s.genres << genre_gourmet
        end
      end

      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("OPENAI_API_KEY").and_return("test-key")

        stub_openai_chat(response_content: {
          picks: [ { n: 1, d: "おすすめです" } ],
          intro: "素敵なエリアです",
          closing: "楽しんでください"
        }.to_json)
      end

      context "ログイン済み・自分のプランの場合" do
        before { sign_in user }

        it "ジャンル指定でAI提案を取得する" do
          post suggest_api_ai_area_path, params: area_params.merge(
            mode: "plan",
            slots: [ { genre_id: genre_gourmet.id } ]
          ), headers: { "Accept" => "text/vnd.turbo-stream.html" }

          expect(response).to have_http_status(:ok)
        end

        it "複数スロットでAI提案を取得する" do
          spot_onsen = create(:spot, lat: 35.6780, lng: 139.6520)
          spot_onsen.genres << genre_onsen

          post suggest_api_ai_area_path, params: area_params.merge(
            mode: "plan",
            slots: [ { genre_id: genre_gourmet.id }, { genre_id: genre_onsen.id } ]
          ), headers: { "Accept" => "text/vnd.turbo-stream.html" }

          expect(response).to have_http_status(:ok)
        end

        it "おまかせスロット（genre_id: nil）でも動作する" do
          post suggest_api_ai_area_path, params: area_params.merge(
            mode: "plan",
            slots: [ { genre_id: nil }, { genre_id: genre_gourmet.id } ]
          ), headers: { "Accept" => "text/vnd.turbo-stream.html" }

          expect(response).to have_http_status(:ok)
        end

        it "AIチャットメッセージが保存される" do
          expect {
            post suggest_api_ai_area_path, params: area_params.merge(
              mode: "plan",
              slots: [ { genre_id: genre_gourmet.id } ]
            ), headers: { "Accept" => "text/vnd.turbo-stream.html" }
          }.to change { plan.ai_chat_messages.count }.by(1)
        end

        it "Turbo Stream形式でレスポンスを返す" do
          post suggest_api_ai_area_path, params: area_params.merge(
            mode: "plan",
            slots: [ { genre_id: genre_gourmet.id } ]
          ), headers: { "Accept" => "text/vnd.turbo-stream.html" }

          expect(response.content_type).to include("text/vnd.turbo-stream.html")
        end
      end

      context "他人のプランの場合" do
        let(:other_plan) { create(:plan, user: other_user) }
        before { sign_in user }

        it "404エラーを返す" do
          post suggest_api_ai_area_path, params: area_params.merge(
            plan_id: other_plan.id,
            mode: "plan",
            slots: [ { genre_id: genre_gourmet.id } ]
          ), headers: { "Accept" => "text/vnd.turbo-stream.html" }

          expect(response).to have_http_status(:not_found)
        end
      end

      context "未ログインの場合" do
        it "ログイン画面にリダイレクトする" do
          post suggest_api_ai_area_path, params: area_params.merge(
            mode: "plan",
            slots: [ { genre_id: genre_gourmet.id } ]
          )

          expect(response).to redirect_to(new_user_session_path)
        end
      end
    end

    context "スポットモード" do
      let!(:genre) { create(:genre, name: "ラーメン", slug: "ramen") }
      let!(:spot1) { create(:spot, lat: 35.6770, lng: 139.6510, name: "ラーメン屋1") }
      let!(:spot2) { create(:spot, lat: 35.6780, lng: 139.6520, name: "ラーメン屋2") }

      before do
        spot1.genres << genre
        spot2.genres << genre

        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("OPENAI_API_KEY").and_return("test-key")

        stub_openai_chat(response_content: {
          intro: "人気のラーメン店です",
          closing: "ぜひ追加してください"
        }.to_json)

        sign_in user
      end

      it "ジャンル・件数指定でスポット提案を取得する" do
        post suggest_api_ai_area_path, params: area_params.merge(
          mode: "spots",
          genre_id: genre.id,
          count: 3
        ), headers: { "Accept" => "text/vnd.turbo-stream.html" }

        expect(response).to have_http_status(:ok)
      end

      it "存在しないジャンルでもエラーにならない" do
        post suggest_api_ai_area_path, params: area_params.merge(
          mode: "spots",
          genre_id: 99999,
          count: 3
        ), headers: { "Accept" => "text/vnd.turbo-stream.html" }

        # エラーメッセージ付きで200を返す（500にはならない）
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "POST /api/ai_area/finish" do
    before { sign_in user }

    context "最後のメッセージがmode_selectでない場合" do
      before do
        create(:ai_chat_message, :assistant_conversation, user: user, plan: plan)
      end

      it "mode_selectメッセージを追加する" do
        expect {
          post finish_api_ai_area_path, params: { plan_id: plan.id },
               headers: { "Accept" => "text/vnd.turbo-stream.html" }
        }.to change { plan.ai_chat_messages.count }.by(1)

        expect(response).to have_http_status(:ok)
      end
    end

    context "最後のメッセージがmode_selectの場合" do
      before do
        create(:ai_chat_message, user: user, plan: plan, role: "assistant",
               content: { type: "mode_select", message: "test" }.to_json)
      end

      it "何も追加しない" do
        expect {
          post finish_api_ai_area_path, params: { plan_id: plan.id },
               headers: { "Accept" => "text/vnd.turbo-stream.html" }
        }.not_to change { plan.ai_chat_messages.count }

        expect(response).to have_http_status(:no_content)
      end
    end
  end
end
