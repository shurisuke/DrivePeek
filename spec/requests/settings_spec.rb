# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Settings", type: :request do
  let(:user) { create(:user) }

  describe "GET /settings" do
    context "ログイン済みの場合" do
      before { sign_in user }

      it "正常に表示される" do
        get settings_path
        expect(response).to have_http_status(:ok)
      end
    end

    it_behaves_like "要認証エンドポイント（リダイレクト）", :get, -> { settings_path }
  end

  describe "GET /settings/profile" do
    context "ログイン済みの場合" do
      before { sign_in user }

      it "正常に表示される" do
        get profile_settings_path
        expect(response).to have_http_status(:ok)
      end
    end

    it_behaves_like "要認証エンドポイント（リダイレクト）", :get, -> { profile_settings_path }
  end

  describe "PATCH /settings/profile" do
    context "ログイン済みの場合" do
      before { sign_in user }

      it "プロフィールを更新する" do
        patch profile_settings_path, params: {
          user: { age_group: "thirties", gender: "male", residence: "東京都" }
        }

        expect(response).to redirect_to(settings_path)
        user.reload
        expect(user.age_group).to eq("thirties")
        expect(user.gender).to eq("male")
        expect(user.residence).to eq("東京都")
      end

      it "サインアップ後の場合はプラン作成ページにリダイレクトする" do
        patch profile_settings_path, params: {
          user: { age_group: "twenties", gender: "female", residence: "大阪府" },
          from: "signup"
        }

        expect(response).to redirect_to(new_plan_path)
      end

      it "バリデーションエラーの場合はプロフィールページを再表示" do
        allow_any_instance_of(User).to receive(:update).and_return(false)

        patch profile_settings_path, params: {
          user: { age_group: "invalid" }
        }

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    it_behaves_like "要認証エンドポイント（リダイレクト）",
                    :patch,
                    -> { profile_settings_path },
                    params: { user: { age_group: "30s" } }
  end

  describe "GET /settings/email" do
    context "ログイン済みの場合" do
      before { sign_in user }

      it "正常に表示される" do
        get email_settings_path
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "GET /settings/password" do
    context "ログイン済みの場合" do
      before { sign_in user }

      it "正常に表示される" do
        get password_settings_path
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "GET /settings/sns" do
    context "ログイン済みの場合" do
      before { sign_in user }

      it "正常に表示される" do
        get sns_settings_path
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "GET /settings/account" do
    context "ログイン済みの場合" do
      before { sign_in user }

      it "正常に表示される" do
        get account_settings_path
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "GET /settings/visibility" do
    context "ログイン済みの場合" do
      before { sign_in user }

      it "正常に表示される" do
        get visibility_settings_path
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "PATCH /settings" do
    context "ログイン済みの場合" do
      before { sign_in user }

      it "ステータスをactiveに変更する" do
        patch settings_path, params: { status: "active" }

        expect(response).to redirect_to(visibility_settings_path)
        expect(user.reload.status).to eq("active")
      end

      it "ステータスをhiddenに変更する" do
        patch settings_path, params: { status: "hidden" }

        expect(response).to redirect_to(visibility_settings_path)
        expect(user.reload.status).to eq("hidden")
      end
    end

    it_behaves_like "要認証エンドポイント（リダイレクト）",
                    :patch,
                    -> { settings_path },
                    params: { status: "active" }
  end
end
