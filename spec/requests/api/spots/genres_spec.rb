# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::Spots::Genres", type: :request do
  let(:user) { create(:user) }
  let(:spot) { create(:spot) }

  describe "GET /api/spots/:spot_id/genres" do
    before do
      sign_in user
      allow_any_instance_of(Spot).to receive(:detect_genres!).and_return(true)
    end

    it "正常に表示される" do
      get api_spot_genres_path(spot)
      expect(response).to have_http_status(:ok)
    end

    it "インラインモードで表示できる" do
      get api_spot_genres_path(spot), params: { inline: "true" }
      expect(response).to have_http_status(:ok)
    end

    it "存在しないスポットの場合は404を返す" do
      get api_spot_genres_path(spot_id: 0)
      expect(response).to have_http_status(:not_found)
    end

    context "未ログインの場合" do
      before { sign_out user }

      it "401エラーを返す" do
        get api_spot_genres_path(spot), as: :json
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
