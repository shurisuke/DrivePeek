# frozen_string_literal: true

require "rails_helper"

RSpec.describe "SuggestionLogs", type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:plan) { create(:plan, user: user) }

  before do
    stub_google_geocoding_api
    stub_google_directions_api
  end

  describe "DELETE /suggestion_logs/destroy_all" do
    before do
      create(:suggestion_log, :user_message, user: user, plan: plan)
      create(:suggestion_log, :assistant_conversation, user: user, plan: plan)
    end

    context "ログイン済み・自分のプランの場合" do
      before { sign_in user }

      it "会話履歴を全削除する" do
        expect {
          delete destroy_all_suggestion_logs_path, params: { plan_id: plan.id },
                 headers: { "Accept" => "text/vnd.turbo-stream.html" }
        }.to change { plan.suggestion_logs.count }.from(2).to(0)

        expect(response).to have_http_status(:ok)
      end

      it "Turbo Stream形式でレスポンスを返す" do
        delete destroy_all_suggestion_logs_path, params: { plan_id: plan.id },
               headers: { "Accept" => "text/vnd.turbo-stream.html" }

        expect(response.content_type).to include("text/vnd.turbo-stream.html")
      end
    end

    context "他人のプランの場合" do
      let(:other_plan) { create(:plan, user: other_user) }
      before do
        create(:suggestion_log, :user_message, user: other_user, plan: other_plan)
        sign_in user
      end

      it "404エラーを返す" do
        delete destroy_all_suggestion_logs_path, params: { plan_id: other_plan.id },
               headers: { "Accept" => "text/vnd.turbo-stream.html" }
        expect(response).to have_http_status(:not_found)
      end

      it "他人のメッセージは削除されない" do
        expect {
          delete destroy_all_suggestion_logs_path, params: { plan_id: other_plan.id },
                 headers: { "Accept" => "text/vnd.turbo-stream.html" }
        }.not_to change { other_plan.suggestion_logs.count }
      end
    end

    context "未ログインの場合" do
      it "ログイン画面にリダイレクトする" do
        delete destroy_all_suggestion_logs_path, params: { plan_id: plan.id }

        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
