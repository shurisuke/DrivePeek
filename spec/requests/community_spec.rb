# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Community", type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }

  before do
    stub_google_geocoding_api
    stub_google_directions_api
  end

  describe "GET /community" do
    # for_communityスコープは2スポット以上のプランのみ表示
    let!(:public_plan) { create(:plan, :with_spots, user: other_user, title: "公開プラン") }
    let!(:no_spots_plan) { create(:plan, user: other_user, title: "スポットなしプラン") }

    it "公開プラン一覧を表示する" do
      get community_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("公開プラン")
      expect(response.body).not_to include("スポットなしプラン")
    end

    it "未ログインでもアクセス可能" do
      get community_path
      expect(response).to have_http_status(:ok)
    end

    context "ソート機能" do
      let!(:old_plan) { create(:plan, :with_spots, user: other_user, title: "古いプラン", created_at: 2.days.ago) }
      let!(:new_plan) { create(:plan, :with_spots, user: other_user, title: "新しいプラン", created_at: 1.day.ago) }

      it "sort=oldestで古い順に並ぶ" do
        get community_path, params: { sort: "oldest" }
        expect(response).to have_http_status(:ok)
        expect(response.body.index("古いプラン")).to be < response.body.index("新しいプラン")
      end

      it "sort=popularで人気順に並ぶ" do
        # 古いプランにお気に入りを追加
        create(:favorite_plan, plan: old_plan)

        get community_path, params: { sort: "popular" }
        expect(response).to have_http_status(:ok)
        # 古いプランの方がお気に入り数が多いので先に表示される
        expect(response.body.index("古いプラン")).to be < response.body.index("新しいプラン")
      end

      it "無効なsortパラメータはデフォルト（newest）になる" do
        get community_path, params: { sort: "invalid" }
        expect(response).to have_http_status(:ok)
      end
    end
  end
end
