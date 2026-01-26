# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::PlanSpots", type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:plan) { create(:plan, user: user) }
  let(:spot) { create(:spot) }

  before do
    stub_google_geocoding_api
    stub_google_directions_api
  end

  describe "POST /api/plans/:plan_id/plan_spots" do
    context "ログイン済み・自分のプランの場合" do
      before { sign_in user }

      it "スポットをプランに追加する" do
        expect {
          post api_plan_plan_spots_path(plan), params: { spot_id: spot.id }, as: :json
        }.to change(PlanSpot, :count).by(1)

        expect(response).to have_http_status(:created)
      end

      it "追加されたplan_spotの情報を返す" do
        post api_plan_plan_spots_path(plan), params: { spot_id: spot.id }, as: :json

        json = response.parsed_body
        expect(json["plan_spot_id"]).to be_present
        expect(json["spot_id"]).to eq(spot.id)
      end

      it "存在しないスポットの場合404を返す" do
        post api_plan_plan_spots_path(plan), params: { spot_id: 99999 }, as: :json

        expect(response).to have_http_status(:not_found)
      end

      it "Turbo Stream形式でも動作する" do
        post api_plan_plan_spots_path(plan),
             params: { spot_id: spot.id },
             headers: { "Accept" => "text/vnd.turbo-stream.html" }

        expect(response).to have_http_status(:ok)
        expect(response.content_type).to include("text/vnd.turbo-stream.html")
      end
    end

    context "他人のプランの場合" do
      let(:other_plan) { create(:plan, user: other_user) }
      before { sign_in user }

      it "404エラーを返す" do
        post api_plan_plan_spots_path(other_plan), params: { spot_id: spot.id }, as: :json
        expect(response).to have_http_status(:not_found)
      end
    end

    context "未ログインの場合" do
      it "401エラーを返す" do
        post api_plan_plan_spots_path(plan), params: { spot_id: spot.id }, as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "POST /api/plans/:plan_id/plan_spots/adopt" do
    let!(:spot1) { create(:spot) }
    let!(:spot2) { create(:spot) }
    let!(:spot3) { create(:spot) }

    context "ログイン済み・自分のプランの場合" do
      before { sign_in user }

      it "複数スポットを一括追加する" do
        spots_params = [
          { spot_id: spot1.id },
          { spot_id: spot2.id },
          { spot_id: spot3.id }
        ]

        expect {
          post adopt_api_plan_plan_spots_path(plan), params: { spots: spots_params }, as: :json
        }.to change { plan.plan_spots.count }.by(3)

        expect(response).to have_http_status(:ok)
      end

      it "既存スポットを置換する" do
        existing_spot = create(:spot)
        create(:plan_spot, plan: plan, spot: existing_spot)

        spots_params = [
          { spot_id: spot1.id },
          { spot_id: spot2.id }
        ]

        post adopt_api_plan_plan_spots_path(plan), params: { spots: spots_params }, as: :json

        expect(plan.reload.plan_spots.count).to eq(2)
        expect(plan.plan_spots.pluck(:spot_id)).to match_array([ spot1.id, spot2.id ])
      end

      it "空のスポットリストは422を返す" do
        post adopt_api_plan_plan_spots_path(plan), params: { spots: [] }, as: :json

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "Turbo Stream形式でも動作する" do
        spots_params = [ { spot_id: spot1.id } ]

        post adopt_api_plan_plan_spots_path(plan),
             params: { spots: spots_params },
             headers: { "Accept" => "text/vnd.turbo-stream.html" }

        expect(response).to have_http_status(:ok)
      end
    end

    context "他人のプランの場合" do
      let(:other_plan) { create(:plan, user: other_user) }
      before { sign_in user }

      it "404エラーを返す" do
        spots_params = [ { spot_id: spot1.id } ]

        post adopt_api_plan_plan_spots_path(other_plan), params: { spots: spots_params }, as: :json
        expect(response).to have_http_status(:not_found)
      end
    end

    context "未ログインの場合" do
      it "401エラーを返す" do
        spots_params = [ { spot_id: spot1.id } ]

        post adopt_api_plan_plan_spots_path(plan), params: { spots: spots_params }, as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
