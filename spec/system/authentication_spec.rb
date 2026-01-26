# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Authentication", type: :system do
  describe "ログイン画面" do
    it "ログイン画面が表示される" do
      visit new_user_session_path

      expect(page).to have_content("ログイン")
    end

    it "ログイン方法選択が表示される" do
      visit new_user_session_path

      expect(page).to have_link("メールアドレスでログイン")
    end

    it "メールフォームに遷移できる" do
      visit new_user_session_path(method: :email)

      expect(page).to have_field("メールアドレス")
      expect(page).to have_field("パスワード")
      expect(page).to have_button("ログイン")
    end
  end

  describe "新規登録画面" do
    it "新規登録画面が表示される" do
      visit new_user_registration_path

      expect(page).to have_content("新規登録")
    end

    it "登録方法選択が表示される" do
      visit new_user_registration_path

      expect(page).to have_link("メールアドレスで登録")
    end

    it "メールフォームに遷移できる" do
      visit new_user_registration_path(method: :email)

      expect(page).to have_field("メールアドレス")
      expect(page).to have_field("パスワード")
      expect(page).to have_button("登録する")
    end
  end
end
