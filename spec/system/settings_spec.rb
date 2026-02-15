# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Settings", type: :system do
  let(:user) { create(:user) }

  describe "設定画面" do
    context "未ログインの場合" do
      it "ログイン画面にリダイレクトする" do
        visit settings_path

        expect(page).to have_current_path(new_user_session_path)
      end
    end

    context "ログイン済みの場合" do
      before { sign_in user }

      it "設定ページが表示される" do
        visit settings_path

        expect(page).to have_content("設定")
      end

      it "メニュー項目が表示される" do
        visit settings_path

        expect(page).to have_content("プロフィール")
        expect(page).to have_content("公開設定")
        expect(page).to have_content("SNS連携")
        expect(page).to have_content("ログアウト・退会")
      end

      it "プロフィール設定ページに遷移できる" do
        visit settings_path
        click_link "プロフィール"

        expect(page).to have_current_path(profile_settings_path)
      end

      it "公開設定ページに遷移できる" do
        visit settings_path
        click_link "公開設定"

        expect(page).to have_current_path(visibility_settings_path)
      end
    end
  end

  describe "プロフィール設定" do
    before { sign_in user }

    it "プロフィール設定ページが表示される" do
      visit profile_settings_path

      expect(page).to have_content("プロフィール")
      expect(page).to have_button("変更を保存")
    end
  end

  describe "公開設定" do
    before { sign_in user }

    it "公開設定ページが表示される" do
      visit visibility_settings_path

      expect(page).to have_content("公開設定")
    end
  end
end
