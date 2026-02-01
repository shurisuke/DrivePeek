# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::GoalPoints", type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:plan) { create(:plan, user: user) }

  before do
    stub_google_geocoding_api
    stub_google_directions_api
  end

  describe "PATCH /api/goal_point" do
    let(:goal_point_params) do
      {
        plan_id: plan.id,
        goal_point: {
          lat: 35.6812,
          lng: 139.7671,
          address: "東京都千代田区"
        }
      }
    end

    context "ログイン済み・自分のプランの場合" do
      before { sign_in user }

      it "帰宅地点を設定する" do
        patch api_goal_point_path, params: goal_point_params, as: :json

        expect(response).to have_http_status(:ok)
        expect(plan.reload.goal_point).to be_present
        expect(plan.goal_point.address).to eq("東京都千代田区")
      end

      it "既存の帰宅地点を更新する" do
        create(:goal_point, plan: plan, address: "旧住所")

        patch api_goal_point_path, params: goal_point_params, as: :json

        expect(response).to have_http_status(:ok)
        expect(plan.reload.goal_point.address).to eq("東京都千代田区")
      end

      it "座標情報を返す" do
        patch api_goal_point_path, params: goal_point_params, as: :json

        json = response.parsed_body
        expect(json["lat"]).to eq(35.6812)
        expect(json["lng"]).to eq(139.7671)
        expect(json["address"]).to eq("東京都千代田区")
      end

      it "Turbo Stream形式でも動作する" do
        patch api_goal_point_path,
              params: goal_point_params,
              headers: { "Accept" => "text/vnd.turbo-stream.html" }

        expect(response).to have_http_status(:ok)
        expect(response.content_type).to include("text/vnd.turbo-stream.html")
      end
    end

    context "他人のプランの場合" do
      let(:other_plan) { create(:plan, user: other_user) }
      before { sign_in user }

      it "404エラーを返す" do
        patch api_goal_point_path, params: goal_point_params.merge(plan_id: other_plan.id), as: :json
        expect(response).to have_http_status(:not_found)
      end
    end

    context "未ログインの場合" do
      it "401エラーを返す" do
        patch api_goal_point_path, params: goal_point_params, as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
