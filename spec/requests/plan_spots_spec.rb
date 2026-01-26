# frozen_string_literal: true

require "rails_helper"

RSpec.describe "PlanSpots", type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:plan) { create(:plan, user: user) }
  let(:spot) { create(:spot) }
  let!(:plan_spot) { create(:plan_spot, plan: plan, spot: spot) }

  before do
    stub_google_geocoding_api
    stub_google_directions_api
  end

  describe "DELETE /plans/:plan_id/plan_spots/:id" do
    context "ログイン済み・自分のプランの場合" do
      before { sign_in user }

      it "スポットをプランから削除する" do
        expect {
          delete plan_plan_spot_path(plan, plan_spot),
                 headers: { "Accept" => "text/vnd.turbo-stream.html" }
        }.to change(PlanSpot, :count).by(-1)

        expect(response).to have_http_status(:ok)
      end

      it "Turbo Stream形式でレスポンスを返す" do
        delete plan_plan_spot_path(plan, plan_spot),
               headers: { "Accept" => "text/vnd.turbo-stream.html" }

        expect(response.content_type).to include("text/vnd.turbo-stream.html")
      end

      it "HTML形式ではリダイレクトする" do
        delete plan_plan_spot_path(plan, plan_spot)

        expect(response).to redirect_to(edit_plan_path(plan))
      end
    end

    context "他人のプランの場合" do
      let(:other_plan) { create(:plan, user: other_user) }
      let!(:other_plan_spot) { create(:plan_spot, plan: other_plan, spot: spot) }
      before { sign_in user }

      it "404エラーを返す" do
        delete plan_plan_spot_path(other_plan, other_plan_spot),
               headers: { "Accept" => "text/vnd.turbo-stream.html" }
        expect(response).to have_http_status(:not_found)
      end

      it "スポットは削除されない" do
        expect {
          delete plan_plan_spot_path(other_plan, other_plan_spot),
                 headers: { "Accept" => "text/vnd.turbo-stream.html" }
        }.not_to change(PlanSpot, :count)
      end
    end

    context "未ログインの場合" do
      it "ログイン画面にリダイレクトする" do
        delete plan_plan_spot_path(plan, plan_spot)

        expect(response).to redirect_to(new_user_session_path)
      end

      it "スポットは削除されない" do
        expect {
          delete plan_plan_spot_path(plan, plan_spot)
        }.not_to change(PlanSpot, :count)
      end
    end
  end
end
