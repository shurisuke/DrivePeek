# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::PlanSpots::TollUsed", type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:plan) { create(:plan, user: user) }
  let(:spot) { create(:spot) }
  let!(:plan_spot) { create(:plan_spot, plan: plan, spot: spot, toll_used: false) }

  before do
    stub_google_geocoding_api
    stub_google_directions_api
  end

  describe "PATCH /api/plans/:plan_id/plan_spots/:id/toll_used" do
    context "ログイン済み・自分のプランの場合" do
      before { sign_in user }

      it "有料道路設定をtrueに更新する" do
        patch toll_used_api_plan_plan_spot_path(plan, plan_spot),
              params: { toll_used: true },
              as: :json

        expect(response).to have_http_status(:ok)
        expect(plan_spot.reload.toll_used).to be true
      end

      it "有料道路設定をfalseに更新する" do
        plan_spot.update!(toll_used: true)

        patch toll_used_api_plan_plan_spot_path(plan, plan_spot),
              params: { toll_used: false },
              as: :json

        expect(response).to have_http_status(:ok)
        expect(plan_spot.reload.toll_used).to be false
      end

      it "レスポンスに必要な情報が含まれる" do
        patch toll_used_api_plan_plan_spot_path(plan, plan_spot),
              params: { toll_used: true },
              as: :json

        json = response.parsed_body
        expect(json["plan_spot_id"]).to eq(plan_spot.id)
        expect(json["toll_used"]).to be true
        expect(json["spots"]).to be_an(Array)
        expect(json["footer"]).to include("spots_only_distance", "with_goal_distance")
      end
    end

    context "他人のプランの場合" do
      let(:other_plan) { create(:plan, user: other_user) }
      let!(:other_plan_spot) { create(:plan_spot, plan: other_plan, spot: spot) }
      before { sign_in user }

      it "404エラーを返す" do
        patch toll_used_api_plan_plan_spot_path(other_plan, other_plan_spot),
              params: { toll_used: true },
              as: :json

        expect(response).to have_http_status(:not_found)
      end
    end

    context "未ログインの場合" do
      it "401エラーを返す" do
        patch toll_used_api_plan_plan_spot_path(plan, plan_spot),
              params: { toll_used: true },
              as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
