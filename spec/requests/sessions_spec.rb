# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Sessions", type: :request do
  let(:user) { create(:user, email: "test@example.com", password: "password123") }

  describe "GET /users/sign_in" do
    it "ログイン画面を表示する" do
      get new_user_session_path

      expect(response).to have_http_status(:ok)
    end

    context "ログイン済みの場合" do
      before { sign_in user }

      it "プラン作成画面にリダイレクトする" do
        get new_user_session_path

        expect(response).to redirect_to(new_plan_path)
      end
    end
  end

  describe "POST /users/sign_in" do
    context "正しい認証情報の場合" do
      it "ログインしてプラン作成画面にリダイレクトする" do
        post user_session_path, params: {
          user: { email: user.email, password: "password123" }
        }

        expect(response).to redirect_to(new_plan_path)
      end

      it "ログイン後はcurrent_userが設定される" do
        post user_session_path, params: {
          user: { email: user.email, password: "password123" }
        }
        follow_redirect!

        expect(controller.current_user).to eq(user)
      end
    end

    context "誤ったパスワードの場合" do
      it "ログインに失敗する" do
        post user_session_path, params: {
          user: { email: user.email, password: "wrong_password" }
        }

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "存在しないメールアドレスの場合" do
      it "ログインに失敗する" do
        post user_session_path, params: {
          user: { email: "nonexistent@example.com", password: "password123" }
        }

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "DELETE /users/sign_out" do
    context "ログイン済みの場合" do
      before { sign_in user }

      it "ログアウトしてトップページにリダイレクトする" do
        delete destroy_user_session_path

        expect(response).to redirect_to(unauthenticated_root_path)
      end

      it "ログアウト後はcurrent_userがnilになる" do
        delete destroy_user_session_path
        follow_redirect!

        expect(controller.current_user).to be_nil
      end
    end

    context "未ログインの場合" do
      it "トップページにリダイレクトする" do
        delete destroy_user_session_path

        expect(response).to redirect_to(unauthenticated_root_path)
      end
    end
  end
end
