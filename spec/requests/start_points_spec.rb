# frozen_string_literal: true

require "rails_helper"

RSpec.describe "StartPoints", type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:plan) { create(:plan, user: user) }

  before do
    stub_google_geocoding_api
    stub_google_directions_api
  end

  describe "PATCH /plans/:plan_id/start_point" do
    let(:start_point_params) do
      {
        start_point: {
          lat: 35.6762,
          lng: 139.6503,
          address: "東京都渋谷区",
          prefecture: "東京都",
          city: "渋谷区"
        }
      }
    end
    let(:turbo_stream_headers) { { "Accept" => "text/vnd.turbo-stream.html" } }

    context "ログイン済み・自分のプランの場合" do
      before { sign_in user }

      it "出発地点を設定する" do
        patch plan_start_point_path(plan), params: start_point_params, headers: turbo_stream_headers

        expect(response).to have_http_status(:ok)
        expect(plan.reload.start_point).to be_present
        expect(plan.start_point.address).to eq("東京都渋谷区")
      end

      it "既存の出発地点を更新する" do
        create(:start_point, plan: plan, address: "旧住所")

        patch plan_start_point_path(plan), params: start_point_params, headers: turbo_stream_headers

        expect(response).to have_http_status(:ok)
        expect(plan.reload.start_point.address).to eq("東京都渋谷区")
      end

      it "toll_usedのみを更新できる" do
        create(:start_point, plan: plan, toll_used: false)

        patch plan_start_point_path(plan),
              params: { start_point: { toll_used: true } },
              headers: turbo_stream_headers

        expect(response).to have_http_status(:ok)
        expect(plan.reload.start_point.toll_used).to be true
      end

      it "Turbo Stream形式でレスポンスを返す" do
        patch plan_start_point_path(plan),
              params: start_point_params,
              headers: turbo_stream_headers

        expect(response).to have_http_status(:ok)
        expect(response.content_type).to include("text/vnd.turbo-stream.html")
      end

      it "departure_timeを設定できる" do
        params = {
          start_point: {
            lat: 35.6762,
            lng: 139.6503,
            address: "東京都渋谷区",
            departure_time: "09:00"
          }
        }

        patch plan_start_point_path(plan), params: params, headers: turbo_stream_headers

        expect(response).to have_http_status(:ok)
        expect(plan.reload.start_point.departure_time.strftime("%H:%M")).to eq("09:00")
      end
    end

    context "他人のプランの場合" do
      let(:other_plan) { create(:plan, user: other_user) }
      before { sign_in user }

      it "404エラーを返す" do
        patch plan_start_point_path(other_plan), params: start_point_params, as: :json
        expect(response).to have_http_status(:not_found)
      end
    end

    context "未ログインの場合" do
      it "401エラーを返す" do
        patch plan_start_point_path(plan), params: start_point_params, as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
