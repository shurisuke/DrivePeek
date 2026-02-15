# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Contacts", type: :system do
  describe "お問い合わせフォーム" do
    it "お問い合わせページが表示される" do
      visit new_contact_path

      expect(page).to have_content("お問い合わせ")
    end

    it "フォーム項目が表示される" do
      visit new_contact_path

      expect(page).to have_select("contact_category")
      expect(page).to have_field("contact_body")
      expect(page).to have_field("contact_email")
      expect(page).to have_button("送信する")
    end

    it "お問い合わせを送信できる" do
      visit new_contact_path

      select "不具合報告", from: "contact_category"
      fill_in "contact_body", with: "テストのお問い合わせ内容です。"
      fill_in "contact_email", with: "test@example.com"
      click_button "送信する"

      expect(page).to have_content("お問い合わせを送信しました")
    end

    it "必須項目が空の場合エラーが表示される" do
      visit new_contact_path

      click_button "送信する"

      expect(page).to have_css(".auth-errors")
    end

    context "ログイン済みの場合" do
      let(:user) { create(:user, email: "logged_in@example.com") }

      before { sign_in user }

      it "メールアドレスが自動入力される" do
        visit new_contact_path

        expect(page).to have_field("contact_email", with: "logged_in@example.com")
      end
    end
  end
end
