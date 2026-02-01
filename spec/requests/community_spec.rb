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
  end
end
