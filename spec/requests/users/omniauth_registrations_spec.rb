# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Users::OmniauthRegistrations", type: :request do
  let(:user) { create(:user) }

  describe "DELETE /users/auth/unlink/:provider" do
    context "ログイン済みの場合" do
      before { sign_in user }

      context "SNS連携がある場合" do
        let!(:identity) { create(:identity, user: user, provider: "twitter2") }

        it "連携を解除できる" do
          expect {
            delete users_omniauth_unlink_path(provider: "twitter2")
          }.to change(Identity, :count).by(-1)
        end

        it "設定ページにリダイレクトする" do
          delete users_omniauth_unlink_path(provider: "twitter2")
          expect(response).to redirect_to(sns_settings_path)
        end
      end

      context "SNSのみユーザーで連携が1つの場合" do
        let(:sns_only_user) { create(:user, encrypted_password: "") }
        let!(:identity) { create(:identity, user: sns_only_user, provider: "twitter2") }

        before do
          sign_out user
          sign_in sns_only_user
          allow_any_instance_of(User).to receive(:sns_only_user?).and_return(true)
        end

        it "解除できずリダイレクトする" do
          expect {
            delete users_omniauth_unlink_path(provider: "twitter2")
          }.not_to change(Identity, :count)

          expect(response).to redirect_to(sns_settings_path)
        end
      end

      context "存在しない連携の場合" do
        it "リダイレクトする" do
          delete users_omniauth_unlink_path(provider: "twitter2")
          expect(response).to redirect_to(sns_settings_path)
        end
      end
    end

    context "未ログインの場合" do
      it "ログインページにリダイレクトする" do
        delete users_omniauth_unlink_path(provider: "twitter2")
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
