# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::PlanSpots::Memos", type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:plan) { create(:plan, user: user) }
  let(:spot) { create(:spot) }
  let!(:plan_spot) { create(:plan_spot, plan: plan, spot: spot, memo: nil) }

  before do
    stub_google_geocoding_api
    stub_google_directions_api
  end

  describe "PATCH /api/plans/:plan_id/plan_spots/:id/memo" do
    context "ログイン済み・自分のプランの場合" do
      before { sign_in user }

      it "メモを更新する" do
        patch memo_api_plan_plan_spot_path(plan, plan_spot),
              params: { plan_spot: { memo: "ここでランチ" } },
              as: :json

        expect(response).to have_http_status(:ok)
        expect(plan_spot.reload.memo).to eq("ここでランチ")
      end

      it "メモを空にする" do
        plan_spot.update!(memo: "既存メモ")

        patch memo_api_plan_plan_spot_path(plan, plan_spot),
              params: { plan_spot: { memo: "" } },
              as: :json

        expect(response).to have_http_status(:ok)
        expect(plan_spot.reload.memo).to eq("")
      end

      it "レスポンスに必要な情報が含まれる" do
        patch memo_api_plan_plan_spot_path(plan, plan_spot),
              params: { plan_spot: { memo: "テストメモ" } },
              as: :json

        json = response.parsed_body
        expect(json["plan_spot_id"]).to eq(plan_spot.id)
        expect(json["memo"]).to eq("テストメモ")
        expect(json["memo_present"]).to be true
        expect(json["memo_html"]).to include("テストメモ")
      end

      it "メモが空の場合memo_presentはfalse" do
        patch memo_api_plan_plan_spot_path(plan, plan_spot),
              params: { plan_spot: { memo: "" } },
              as: :json

        json = response.parsed_body
        expect(json["memo_present"]).to be false
        expect(json["memo_html"]).to eq("")
      end
    end

    context "他人のプランの場合" do
      let(:other_plan) { create(:plan, user: other_user) }
      let!(:other_plan_spot) { create(:plan_spot, plan: other_plan, spot: spot) }
      before { sign_in user }

      it "404エラーを返す" do
        patch memo_api_plan_plan_spot_path(other_plan, other_plan_spot),
              params: { plan_spot: { memo: "不正アクセス" } },
              as: :json

        expect(response).to have_http_status(:not_found)
      end
    end

    context "未ログインの場合" do
      it "401エラーを返す" do
        patch memo_api_plan_plan_spot_path(plan, plan_spot),
              params: { plan_spot: { memo: "テスト" } },
              as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
