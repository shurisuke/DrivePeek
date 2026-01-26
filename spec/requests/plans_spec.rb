# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Plans", type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }

  before do
    stub_google_geocoding_api
    stub_google_directions_api
  end

  describe "GET /plans" do
    # for_communityスコープは2スポット以上のプランのみ表示
    let!(:public_plan) { create(:plan, :with_spots, user: other_user, title: "公開プラン") }
    let!(:no_spots_plan) { create(:plan, user: other_user, title: "スポットなしプラン") }

    it "公開プラン一覧を表示する" do
      get plans_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("公開プラン")
      expect(response.body).not_to include("スポットなしプラン")
    end

    it "未ログインでもアクセス可能" do
      get plans_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /plans/:id" do
    context "公開プランの場合" do
      let(:plan) { create(:plan, user: other_user) }

      it "プラン詳細を表示する" do
        get plan_path(plan)

        expect(response).to have_http_status(:ok)
      end

      it "未ログインでもアクセス可能" do
        get plan_path(plan)
        expect(response).to have_http_status(:ok)
      end
    end

    context "非公開プラン（ユーザーがhidden）の場合" do
      let(:hidden_user) { create(:user, :hidden) }
      let(:plan) { create(:plan, user: hidden_user) }

      it "404エラーを返す" do
        get plan_path(plan)
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "GET /plans/new" do
    context "ログイン済みの場合" do
      before { sign_in user }

      it "プラン作成画面を表示する" do
        get new_plan_path

        expect(response).to have_http_status(:ok)
      end
    end

    context "未ログインの場合" do
      it "ログイン画面にリダイレクトする" do
        get new_plan_path

        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "POST /plans" do
    context "ログイン済みの場合" do
      before { sign_in user }

      it "プランを作成してedit画面にリダイレクトする" do
        expect {
          post plans_path, params: { lat: 35.6762, lng: 139.6503 }
        }.to change(Plan, :count).by(1)

        expect(response).to redirect_to(edit_plan_path(Plan.last))
      end

      it "作成されたプランはユーザーに紐づく" do
        post plans_path, params: { lat: 35.6762, lng: 139.6503 }

        expect(Plan.last.user).to eq(user)
      end
    end

    context "未ログインの場合" do
      it "ログイン画面にリダイレクトする" do
        post plans_path, params: { lat: 35.6762, lng: 139.6503 }

        expect(response).to redirect_to(new_user_session_path)
      end

      it "プランは作成されない" do
        expect {
          post plans_path, params: { lat: 35.6762, lng: 139.6503 }
        }.not_to change(Plan, :count)
      end
    end
  end

  describe "GET /plans/:id/edit" do
    let(:plan) { create(:plan, user: user) }

    context "ログイン済み・自分のプランの場合" do
      before { sign_in user }

      it "プラン編集画面を表示する" do
        get edit_plan_path(plan)

        expect(response).to have_http_status(:ok)
      end
    end

    context "他人のプランの場合" do
      let(:other_plan) { create(:plan, user: other_user) }
      before { sign_in user }

      it "404エラーを返す" do
        get edit_plan_path(other_plan)
        expect(response).to have_http_status(:not_found)
      end
    end

    context "未ログインの場合" do
      it "ログイン画面にリダイレクトする" do
        get edit_plan_path(plan)

        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "PATCH /plans/:id" do
    let(:plan) { create(:plan, user: user, title: "元のタイトル") }

    context "ログイン済み・自分のプランの場合" do
      before { sign_in user }

      it "プランを更新する" do
        patch plan_path(plan), params: { plan: { title: "新しいタイトル" } }

        expect(response).to redirect_to(edit_plan_path(plan))
        expect(plan.reload.title).to eq("新しいタイトル")
      end

      it "JSON形式で更新できる" do
        patch plan_path(plan), params: { plan: { title: "JSONタイトル" } }, as: :json

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["success"]).to be true
        expect(plan.reload.title).to eq("JSONタイトル")
      end
    end

    context "他人のプランの場合" do
      let(:other_plan) { create(:plan, user: other_user) }
      before { sign_in user }

      it "404エラーを返す" do
        patch plan_path(other_plan), params: { plan: { title: "変更" } }
        expect(response).to have_http_status(:not_found)
      end
    end

    context "未ログインの場合" do
      it "ログイン画面にリダイレクトする" do
        patch plan_path(plan), params: { plan: { title: "変更" } }

        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "DELETE /plans/:id" do
    let!(:plan) { create(:plan, user: user) }

    context "ログイン済み・自分のプランの場合" do
      before { sign_in user }

      it "プランを削除する" do
        expect {
          delete plan_path(plan)
        }.to change(Plan, :count).by(-1)
      end

      it "削除後にリダイレクトする" do
        delete plan_path(plan)

        expect(response).to have_http_status(:redirect)
      end
    end

    context "他人のプランの場合" do
      let!(:other_plan) { create(:plan, user: other_user) }
      before { sign_in user }

      it "404エラーを返す" do
        delete plan_path(other_plan)
        expect(response).to have_http_status(:not_found)
      end

      it "プランは削除されない" do
        expect {
          delete plan_path(other_plan)
        }.not_to change(Plan, :count)
      end
    end

    context "未ログインの場合" do
      it "ログイン画面にリダイレクトする" do
        delete plan_path(plan)

        expect(response).to redirect_to(new_user_session_path)
      end

      it "プランは削除されない" do
        expect {
          delete plan_path(plan)
        }.not_to change(Plan, :count)
      end
    end
  end
end
