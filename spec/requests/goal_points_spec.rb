# frozen_string_literal: true

require "rails_helper"

RSpec.describe "GoalPoints", type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:plan) { create(:plan, user: user) }
  let(:other_plan) { create(:plan, user: other_user) }

  describe "PATCH /plans/:plan_id/goal_point" do
    let(:goal_point_params) do
      {
        goal_point: {
          lat: 35.6812,
          lng: 139.7671,
          address: "東京都千代田区"
        }
      }
    end
    let(:turbo_stream_headers) { { "Accept" => "text/vnd.turbo-stream.html" } }

    context "ログイン済み・自分のプランの場合" do
      before { sign_in user }

      it "帰宅地点を設定する" do
        patch plan_goal_point_path(plan), params: goal_point_params, headers: turbo_stream_headers

        expect(response).to have_http_status(:ok)
        expect(plan.reload.goal_point).to be_present
        expect(plan.goal_point.address).to eq("東京都千代田区")
      end

      it "既存の帰宅地点を更新する" do
        plan.goal_point.update!(address: "旧住所")

        patch plan_goal_point_path(plan), params: goal_point_params, headers: turbo_stream_headers

        expect(response).to have_http_status(:ok)
        expect(plan.reload.goal_point.address).to eq("東京都千代田区")
      end

      it "座標情報を保存する" do
        patch plan_goal_point_path(plan), params: goal_point_params, headers: turbo_stream_headers

        goal_point = plan.reload.goal_point
        expect(goal_point.lat).to eq(35.6812)
        expect(goal_point.lng).to eq(139.7671)
        expect(goal_point.address).to eq("東京都千代田区")
      end

      it "Turbo Stream形式でレスポンスを返す" do
        patch plan_goal_point_path(plan),
              params: goal_point_params,
              headers: turbo_stream_headers

        expect(response).to have_http_status(:ok)
        expect(response.content_type).to include("text/vnd.turbo-stream.html")
      end
    end

    context "他人のプランの場合" do
      before { sign_in user }

      it_behaves_like "他人のリソースへのアクセス拒否",
                      :patch,
                      -> { plan_goal_point_path(other_plan) },
                      params: { goal_point: { lat: 35.0 } }
    end

    it_behaves_like "要認証エンドポイント",
                    :patch,
                    -> { plan_goal_point_path(plan) },
                    params: { goal_point: { lat: 35.0 } }
  end
end
