# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::PlanSpots::Reorders", type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:plan) { create(:plan, user: user) }
  let!(:spot1) { create(:spot) }
  let!(:spot2) { create(:spot) }
  let!(:spot3) { create(:spot) }
  let!(:plan_spot1) { create(:plan_spot, plan: plan, spot: spot1, position: 1) }
  let!(:plan_spot2) { create(:plan_spot, plan: plan, spot: spot2, position: 2) }
  let!(:plan_spot3) { create(:plan_spot, plan: plan, spot: spot3, position: 3) }

  before do
    stub_google_geocoding_api
    stub_google_directions_api
  end

  describe "PATCH /api/plan_spots/reorder" do
    context "ログイン済み・自分のプランの場合" do
      before { sign_in user }

      it "スポットの順序を変更する" do
        new_order = [ plan_spot3.id, plan_spot1.id, plan_spot2.id ]

        patch reorder_api_plan_spots_path,
              params: { plan_id: plan.id, ordered_plan_spot_ids: new_order },
              as: :json

        expect(response).to have_http_status(:no_content)

        expect(plan_spot3.reload.position).to eq(1)
        expect(plan_spot1.reload.position).to eq(2)
        expect(plan_spot2.reload.position).to eq(3)
      end

      it "Turbo Stream形式でも動作する" do
        new_order = [ plan_spot2.id, plan_spot3.id, plan_spot1.id ]

        patch reorder_api_plan_spots_path,
              params: { plan_id: plan.id, ordered_plan_spot_ids: new_order },
              headers: { "Accept" => "text/vnd.turbo-stream.html" }

        expect(response).to have_http_status(:ok)
        expect(response.content_type).to include("text/vnd.turbo-stream.html")
      end

      it "不正なIDは422を返す" do
        patch reorder_api_plan_spots_path,
              params: { plan_id: plan.id, ordered_plan_spot_ids: [ "invalid", "ids" ] },
              as: :json

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "配列以外は422を返す" do
        patch reorder_api_plan_spots_path,
              params: { plan_id: plan.id, ordered_plan_spot_ids: "not_an_array" },
              as: :json

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "他人のプランの場合" do
      let(:other_plan) { create(:plan, user: other_user) }
      before { sign_in user }

      it "404エラーを返す" do
        patch reorder_api_plan_spots_path,
              params: { plan_id: other_plan.id, ordered_plan_spot_ids: [ 1, 2, 3 ] },
              as: :json

        expect(response).to have_http_status(:not_found)
      end
    end

    context "未ログインの場合" do
      it "401エラーを返す" do
        patch reorder_api_plan_spots_path,
              params: { plan_id: plan.id, ordered_plan_spot_ids: [ plan_spot1.id ] },
              as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
