# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Favorites", type: :system do
  let(:user) { create(:user) }

  before do
    stub_google_geocoding_api
    stub_google_directions_api
  end

  describe "お気に入り一覧" do
    context "未ログインの場合" do
      it "ログイン画面にリダイレクトする" do
        visit favorites_path

        expect(page).to have_current_path(new_user_session_path)
      end
    end

    context "ログイン済みの場合" do
      before { sign_in user }

      it "お気に入りページが表示される" do
        visit favorites_path

        expect(page).to have_content("お気に入り")
      end

      it "検索フォームが表示される" do
        visit favorites_path

        expect(page).to have_css(".list-page__sidebar")
      end

      it "プラン/スポット切り替えタブが表示される" do
        visit favorites_path

        expect(page).to have_content("プラン")
        expect(page).to have_content("スポット")
      end

      context "お気に入りがない場合" do
        it "プラン空状態メッセージが表示される" do
          visit favorites_path(search_type: "plan")

          expect(page).to have_content("お気に入りプランがありません")
        end

        it "スポット空状態メッセージが表示される" do
          visit favorites_path(search_type: "spot")

          expect(page).to have_content("お気に入りスポットがありません")
        end
      end

      context "お気に入りがある場合" do
        let!(:spot) { create(:spot, name: "テスト観光地") }
        let!(:other_user) { create(:user) }
        let!(:plan) { create(:plan, user: other_user, title: "テスト旅行プラン") }
        let!(:favorite_spot) { create(:favorite_spot, user: user, spot: spot) }
        let!(:favorite_plan) { create(:favorite_plan, user: user, plan: plan) }

        it "お気に入りスポットが表示される" do
          visit favorites_path(search_type: "spot")

          expect(page).to have_content("テスト観光地")
        end

        it "お気に入りプランが表示される" do
          visit favorites_path(search_type: "plan")

          expect(page).to have_content("テスト旅行プラン")
        end
      end
    end
  end
end
