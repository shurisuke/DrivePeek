# frozen_string_literal: true

require "rails_helper"

RSpec.describe "FavoriteSpots", type: :request do
  let(:user) { create(:user) }
  let(:spot) { create(:spot) }

  describe "POST /favorite_spots" do
    context "ログイン済みの場合" do
      before { sign_in user }

      it "お気に入りを作成する" do
        expect {
          post favorite_spots_path, params: { spot_id: spot.id }, as: :turbo_stream
        }.to change(FavoriteSpot, :count).by(1)
      end

      it "正常に完了する" do
        post favorite_spots_path, params: { spot_id: spot.id }, as: :turbo_stream
        expect(response).to have_http_status(:ok)
      end

      it "同じスポットを再度お気に入りにしても重複しない" do
        create(:favorite_spot, user: user, spot: spot)

        expect {
          post favorite_spots_path, params: { spot_id: spot.id }, as: :turbo_stream
        }.not_to change(FavoriteSpot, :count)
      end
    end

    context "未ログインの場合" do
      it "ログインページにリダイレクトする" do
        post favorite_spots_path, params: { spot_id: spot.id }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "DELETE /favorite_spots/:id" do
    let!(:favorite_spot) { create(:favorite_spot, user: user, spot: spot) }

    context "ログイン済みの場合" do
      before { sign_in user }

      it "お気に入りを削除する" do
        expect {
          delete favorite_spot_path(favorite_spot), as: :turbo_stream
        }.to change(FavoriteSpot, :count).by(-1)
      end

      it "正常に完了する" do
        delete favorite_spot_path(favorite_spot), as: :turbo_stream
        expect(response).to have_http_status(:ok)
      end

      it "存在しないお気に入りの場合は404を返す" do
        delete favorite_spot_path(id: 0), as: :turbo_stream
        expect(response).to have_http_status(:not_found)
      end
    end

    context "未ログインの場合" do
      it "ログインページにリダイレクトする" do
        delete favorite_spot_path(favorite_spot)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
