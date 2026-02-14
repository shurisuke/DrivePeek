# frozen_string_literal: true

require "rails_helper"

RSpec.describe "SpotGenres", type: :request do
  let(:user) { create(:user) }
  let(:spot) { create(:spot) }

  describe "GET /spots/:spot_id/genres" do
    before do
      sign_in user
      allow_any_instance_of(Spot).to receive(:detect_genres!).and_return(true)
    end

    it "正常に表示される" do
      get spot_genres_path(spot)
      expect(response).to have_http_status(:ok)
    end

    it "インラインモードで表示できる" do
      get spot_genres_path(spot), params: { inline: "true" }
      expect(response).to have_http_status(:ok)
    end

    it "存在しないスポットの場合は404を返す" do
      get spot_genres_path(spot_id: 0)
      expect(response).to have_http_status(:not_found)
    end

    context "未ログインの場合" do
      before { sign_out user }

      it "ジャンル表示は認証不要（InfoWindow用）" do
        get spot_genres_path(spot)
        expect(response).to have_http_status(:ok)
      end
    end
  end
end
