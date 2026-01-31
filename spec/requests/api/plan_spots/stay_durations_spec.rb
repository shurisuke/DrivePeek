# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::PlanSpots::StayDurations", type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:plan) { create(:plan, user: user) }
  let(:spot) { create(:spot) }
  let!(:plan_spot) { create(:plan_spot, plan: plan, spot: spot, stay_duration: 30) }

  before do
    stub_google_geocoding_api
    stub_google_directions_api
  end

  describe "PATCH /api/plans/:plan_id/plan_spots/:id/stay_duration" do
    context "ログイン済み・自分のプランの場合" do
      before { sign_in user }

      it "滞在時間を更新する" do
        patch stay_duration_api_plan_plan_spot_path(plan, plan_spot),
              params: { stay_duration: 60 },
              as: :json

        expect(response).to have_http_status(:ok)
        expect(plan_spot.reload.stay_duration).to eq(60)
      end

      it "滞在時間を0にする" do
        patch stay_duration_api_plan_plan_spot_path(plan, plan_spot),
              params: { stay_duration: 0 },
              as: :json

        expect(response).to have_http_status(:ok)
        expect(plan_spot.reload.stay_duration).to eq(0)
      end

      it "滞在時間を空にする（nil）" do
        patch stay_duration_api_plan_plan_spot_path(plan, plan_spot),
              params: { stay_duration: "" },
              as: :json

        expect(response).to have_http_status(:ok)
        expect(plan_spot.reload.stay_duration).to be_nil
      end

      it "レスポンスに必要な情報が含まれる" do
        patch stay_duration_api_plan_plan_spot_path(plan, plan_spot),
              params: { stay_duration: 45 },
              as: :json

        json = response.parsed_body
        expect(json["plan_spot_id"]).to eq(plan_spot.id)
        expect(json["stay_duration"]).to eq(45)
      end
    end

    context "他人のプランの場合" do
      let(:other_plan) { create(:plan, user: other_user) }
      let!(:other_plan_spot) { create(:plan_spot, plan: other_plan, spot: spot) }
      before { sign_in user }

      it "404エラーを返す" do
        patch stay_duration_api_plan_plan_spot_path(other_plan, other_plan_spot),
              params: { stay_duration: 60 },
              as: :json

        expect(response).to have_http_status(:not_found)
      end
    end

    context "未ログインの場合" do
      it "401エラーを返す" do
        patch stay_duration_api_plan_plan_spot_path(plan, plan_spot),
              params: { stay_duration: 60 },
              as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
