# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Community", type: :system do
  before do
    stub_google_geocoding_api
    stub_google_directions_api
  end

  describe "みんなの旅一覧（未ログイン）" do
    it "一覧ページが表示される" do
      visit plans_path

      expect(page).to have_content("みんなの旅")
    end

    it "検索フォームが表示される" do
      visit plans_path

      expect(page).to have_css(".list-page__sidebar")
    end

    it "プラン/スポット切り替えタブが表示される" do
      visit plans_path

      expect(page).to have_content("プラン")
      expect(page).to have_content("スポット")
    end
  end
end
