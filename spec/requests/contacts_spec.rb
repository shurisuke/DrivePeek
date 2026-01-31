# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Contacts", type: :request do
  let(:user) { create(:user) }

  describe "GET /contacts/new" do
    context "ログイン済みの場合" do
      before { sign_in user }

      it "正常に表示される" do
        get new_contact_path
        expect(response).to have_http_status(:ok)
      end

      it "メールアドレスが自動入力される" do
        get new_contact_path
        expect(response.body).to include(user.email)
      end
    end

    context "未ログインの場合" do
      it "正常に表示される" do
        get new_contact_path
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "POST /contacts" do
    let(:valid_params) do
      {
        contact: {
          category: "general",
          body: "テストのお問い合わせです。10文字以上必要です。",
          email: "test@example.com"
        }
      }
    end

    context "有効なパラメータの場合" do
      before do
        allow_any_instance_of(Contact).to receive(:submit).and_return(true)
      end

      it "お問い合わせページにリダイレクトする" do
        post contacts_path, params: valid_params
        expect(response).to redirect_to(new_contact_path)
      end

      it "成功メッセージが表示される" do
        post contacts_path, params: valid_params
        follow_redirect!
        expect(response.body).to include("お問い合わせを送信しました")
      end
    end

    context "無効なパラメータの場合" do
      before do
        allow_any_instance_of(Contact).to receive(:submit).and_return(false)
      end

      it "フォームを再表示する" do
        post contacts_path, params: { contact: { body: "", email: "" } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "スパム検知（ハニーポット）の場合" do
      it "リダイレクトする" do
        post contacts_path, params: valid_params.merge(website: "spam")
        expect(response).to redirect_to(new_contact_path)
      end
    end
  end
end
