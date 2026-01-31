# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Spots", type: :request do
  let(:user) { create(:user) }
  let(:spot) { create(:spot) }

  describe "GET /spots/:id" do
    it "正常に表示される" do
      get spot_path(spot)
      expect(response).to have_http_status(:ok)
    end

    it "スポット名が表示される" do
      get spot_path(spot)
      expect(response.body).to include(spot.name)
    end

    context "ログイン済みの場合" do
      before { sign_in user }

      it "正常に表示される" do
        get spot_path(spot)
        expect(response).to have_http_status(:ok)
      end

      context "お気に入り登録済みの場合" do
        let!(:like_spot) { create(:like_spot, user: user, spot: spot) }

        it "正常に表示される" do
          get spot_path(spot)
          expect(response).to have_http_status(:ok)
        end
      end
    end

    context "存在しないスポットの場合" do
      it "404エラーを返す" do
        get spot_path(id: 0)
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
