# frozen_string_literal: true

require "rails_helper"

RSpec.describe "LikePlans", type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:plan) { create(:plan, user: other_user) }

  before do
    stub_google_geocoding_api
    stub_google_directions_api
  end

  describe "POST /like_plans" do
    context "ログイン済みの場合" do
      before { sign_in user }

      it "お気に入りを作成する" do
        expect {
          post like_plans_path, params: { plan_id: plan.id }, as: :turbo_stream
        }.to change(LikePlan, :count).by(1)
      end

      it "正常に完了する" do
        post like_plans_path, params: { plan_id: plan.id }, as: :turbo_stream
        expect(response).to have_http_status(:ok)
      end

      it "同じプランを再度お気に入りにしても重複しない" do
        create(:like_plan, user: user, plan: plan)

        expect {
          post like_plans_path, params: { plan_id: plan.id }, as: :turbo_stream
        }.not_to change(LikePlan, :count)
      end
    end

    context "未ログインの場合" do
      it "ログインページにリダイレクトする" do
        post like_plans_path, params: { plan_id: plan.id }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "DELETE /like_plans/:id" do
    let!(:like_plan) { create(:like_plan, user: user, plan: plan) }

    context "ログイン済みの場合" do
      before { sign_in user }

      it "お気に入りを削除する" do
        expect {
          delete like_plan_path(like_plan), as: :turbo_stream
        }.to change(LikePlan, :count).by(-1)
      end

      it "正常に完了する" do
        delete like_plan_path(like_plan), as: :turbo_stream
        expect(response).to have_http_status(:ok)
      end

      it "存在しないお気に入りの場合は404を返す" do
        delete like_plan_path(id: 0), as: :turbo_stream
        expect(response).to have_http_status(:not_found)
      end
    end

    context "未ログインの場合" do
      it "ログインページにリダイレクトする" do
        delete like_plan_path(like_plan)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
