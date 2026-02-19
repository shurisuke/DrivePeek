# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Plans", type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }

  describe "GET /plans" do
    context "ログイン済みの場合" do
      before { sign_in user }

      let!(:old_plan) { create(:plan, user: user, title: "古いプラン", created_at: 2.days.ago) }
      let!(:new_plan) { create(:plan, user: user, title: "新しいプラン", created_at: 1.day.ago) }

      it "自分のプラン一覧を表示する" do
        get plans_path
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("古いプラン")
        expect(response.body).to include("新しいプラン")
      end

      it "他人のプランは表示されない" do
        other_plan = create(:plan, user: other_user, title: "他人のプラン")
        get plans_path
        expect(response.body).not_to include("他人のプラン")
      end

      context "ソート機能" do
        it "デフォルトは新しい順" do
          get plans_path
          expect(response.body.index("新しいプラン")).to be < response.body.index("古いプラン")
        end

        it "sort=oldestで古い順に並ぶ" do
          get plans_path, params: { sort: "oldest" }
          expect(response.body.index("古いプラン")).to be < response.body.index("新しいプラン")
        end

        it "無効なsortパラメータはデフォルト（newest）になる" do
          get plans_path, params: { sort: "invalid" }
          expect(response).to have_http_status(:ok)
        end
      end
    end

    it_behaves_like "要認証エンドポイント（リダイレクト）", :get, -> { plans_path }
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

    it_behaves_like "要認証エンドポイント（リダイレクト）", :get, -> { new_plan_path }
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

      context "copy_fromパラメータがある場合" do
        let!(:source_plan) { create(:plan, :with_spots, user: other_user, title: "コピー元プラン") }

        it "コピー元プランのスポットをコピーする" do
          post plans_path, params: { lat: 35.6762, lng: 139.6503, copy_from: source_plan.id }

          new_plan = Plan.last
          expect(new_plan.plan_spots.count).to eq(source_plan.plan_spots.count)
          expect(new_plan.title).to eq("コピー元プラン")
        end

        it "存在しないcopy_fromは無視される" do
          post plans_path, params: { lat: 35.6762, lng: 139.6503, copy_from: 999999 }

          expect(Plan.last.plan_spots.count).to eq(0)
        end
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
    let(:other_plan) { create(:plan, user: other_user) }

    context "ログイン済み・自分のプランの場合" do
      before { sign_in user }

      it "プラン編集画面を表示する" do
        get edit_plan_path(plan)

        expect(response).to have_http_status(:ok)
      end
    end

    context "他人のプランの場合" do
      before { sign_in user }

      it_behaves_like "他人のリソースへのアクセス拒否", :get, -> { edit_plan_path(other_plan) }
    end

    it_behaves_like "要認証エンドポイント（リダイレクト）", :get, -> { edit_plan_path(plan) }
  end

  describe "PATCH /plans/:id" do
    let(:plan) { create(:plan, user: user, title: "元のタイトル") }
    let(:other_plan) { create(:plan, user: other_user) }

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

      it "更新失敗時はJSON形式でエラーを返す" do
        plan.errors.add(:base, "テストエラー")
        allow_any_instance_of(Plan).to receive(:update).and_return(false)

        patch plan_path(plan), params: { plan: { title: "" } }, as: :json

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body["success"]).to be false
      end
    end

    context "他人のプランの場合" do
      before { sign_in user }

      it_behaves_like "他人のリソースへのアクセス拒否",
                      :patch,
                      -> { plan_path(other_plan) },
                      params: { plan: { title: "変更" } }
    end

    it_behaves_like "要認証エンドポイント（リダイレクト）",
                    :patch,
                    -> { plan_path(plan) },
                    params: { plan: { title: "変更" } }
  end

  describe "DELETE /plans/:id" do
    let!(:plan) { create(:plan, user: user) }
    let!(:other_plan) { create(:plan, user: other_user) }

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
