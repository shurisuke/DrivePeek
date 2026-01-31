# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::Plans::Previews", type: :request do
  let(:owner) { create(:user, status: :active) }
  let(:user) { create(:user) }
  let(:plan) { create(:plan, user: owner) }

  before do
    stub_google_geocoding_api
    stub_google_directions_api
    sign_in user
  end

  describe "GET /api/plans/:plan_id/preview" do
    it "公開プランのプレビューデータを取得する" do
      get api_plan_preview_path(plan)
      expect(response).to have_http_status(:ok)
    end

    it "JSONを返す" do
      get api_plan_preview_path(plan)
      expect(response.content_type).to include("application/json")
    end

    context "ユーザーが非公開（hidden）の場合" do
      let(:hidden_user) { create(:user, status: :hidden) }
      let(:hidden_plan) { create(:plan, user: hidden_user) }

      it "404を返す" do
        get api_plan_preview_path(hidden_plan)
        expect(response).to have_http_status(:not_found)
      end
    end

    context "存在しないプランの場合" do
      it "404を返す" do
        get api_plan_preview_path(plan_id: 0)
        expect(response).to have_http_status(:not_found)
      end
    end

    context "未ログインの場合" do
      before { sign_out user }

      it "401エラーを返す" do
        get api_plan_preview_path(plan), as: :json
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
