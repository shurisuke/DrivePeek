# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Favorites", type: :request do
  let(:user) { create(:user) }
  let(:spot) { create(:spot) }
  let(:other_user) { create(:user) }
  let(:plan) { create(:plan, user: other_user) }

  before do
    stub_google_geocoding_api
    stub_google_directions_api
  end

  describe "GET /favorites" do
    context "ログイン済みの場合" do
      before { sign_in user }

      context "スポット検索（search_type=spot）" do
        let!(:favorite_spot) { create(:favorite_spot, user: user, spot: spot) }

        it "正常に表示される" do
          get favorites_path, params: { search_type: "spot" }
          expect(response).to have_http_status(:ok)
        end

        it "お気に入りのスポットが表示される" do
          get favorites_path, params: { search_type: "spot" }
          expect(response.body).to include(spot.name)
        end
      end

      context "プラン検索（search_type=plan）" do
        let!(:favorite_plan) { create(:favorite_plan, user: user, plan: plan) }

        it "正常に表示される" do
          get favorites_path, params: { search_type: "plan" }
          expect(response).to have_http_status(:ok)
        end

        it "お気に入りのプランが表示される" do
          get favorites_path, params: { search_type: "plan" }
          expect(response.body).to include(plan.title)
        end
      end

      context "デフォルト（search_type未指定）" do
        it "プラン一覧を表示する" do
          get favorites_path
          expect(response).to have_http_status(:ok)
        end
      end

      context "キーワード検索" do
        let!(:favorite_spot) { create(:favorite_spot, user: user, spot: spot) }

        it "キーワードでフィルタできる" do
          get favorites_path, params: { search_type: "spot", q: spot.name }
          expect(response).to have_http_status(:ok)
        end
      end

      context "都市フィルタ" do
        let!(:favorite_spot) { create(:favorite_spot, user: user, spot: spot) }

        it "都市でフィルタできる" do
          get favorites_path, params: { search_type: "spot", cities: [ spot.city ] }
          expect(response).to have_http_status(:ok)
        end
      end

      context "ジャンルフィルタ" do
        let(:genre) { create(:genre) }
        let(:spot_with_genre) { create(:spot, genres: [ genre ]) }
        let!(:favorite_spot) { create(:favorite_spot, user: user, spot: spot_with_genre) }

        it "ジャンルでフィルタできる" do
          get favorites_path, params: { search_type: "spot", genre_ids: [ genre.id ] }
          expect(response).to have_http_status(:ok)
        end
      end

      context "ソート機能" do
        let(:old_spot) { create(:spot, name: "古いスポット", created_at: 2.days.ago) }
        let(:new_spot) { create(:spot, name: "新しいスポット", created_at: 1.day.ago) }
        let!(:fav_old) { create(:favorite_spot, user: user, spot: old_spot) }
        let!(:fav_new) { create(:favorite_spot, user: user, spot: new_spot) }

        it "sort=oldestで古い順に並ぶ" do
          get favorites_path, params: { search_type: "spot", sort: "oldest" }
          expect(response).to have_http_status(:ok)
          expect(response.body.index("古いスポット")).to be < response.body.index("新しいスポット")
        end

        it "無効なsortパラメータはデフォルト（newest）になる" do
          get favorites_path, params: { search_type: "spot", sort: "invalid" }
          expect(response).to have_http_status(:ok)
        end
      end
    end

    it_behaves_like "要認証エンドポイント（リダイレクト）", :get, -> { favorites_path }
  end
end
