# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Static Pages", type: :system do
  describe "トップページ（未ログイン）" do
    it "トップページが表示される" do
      visit unauthenticated_root_path

      expect(page).to have_content("DrivePeek")
    end
  end

  describe "利用規約" do
    it "利用規約ページが表示される" do
      visit terms_path

      expect(page).to have_content("利用規約")
    end
  end

  describe "プライバシーポリシー" do
    it "プライバシーポリシーページが表示される" do
      visit privacy_path

      expect(page).to have_content("プライバシーポリシー")
    end
  end
end
