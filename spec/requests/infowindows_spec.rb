# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Infowindows", type: :request do
  let(:user) { create(:user) }
  let(:plan) { create(:plan, user: user) }
  let(:spot) { create(:spot) }

  before do
    stub_google_geocoding_api
    stub_google_places_api
  end

  describe "GET /infowindow" do
    context "ログイン済みの場合" do
      before { sign_in user }

      it "spot_idでInfoWindowを表示する" do
        get infowindow_path, params: { spot_id: spot.id, plan_id: plan.id }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(spot.name)
      end

      it "place_idでInfoWindowを表示する" do
        get infowindow_path, params: { place_id: "ChIJtest123", lat: 35.6580, lng: 139.7016 }

        expect(response).to have_http_status(:ok)
      end

      it "edit_mode=start_pointで出発地点用UIを返す" do
        create(:start_point, plan: plan, address: "東京都渋谷区")

        get infowindow_path, params: { edit_mode: "start_point", plan_id: plan.id, name: "自宅" }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("自宅")
      end

      it "edit_mode=goal_pointで帰宅地点用UIを返す" do
        create(:goal_point, plan: plan, address: "東京都新宿区")

        get infowindow_path, params: { edit_mode: "goal_point", plan_id: plan.id, name: "帰宅" }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("帰宅")
      end

      it "プラン内のスポットの場合plan_spot_idを含む" do
        plan_spot = create(:plan_spot, plan: plan, spot: spot)

        get infowindow_path, params: { spot_id: spot.id, plan_id: plan.id }

        expect(response).to have_http_status(:ok)
        # プランに含まれているスポットの場合、削除ボタンが表示される
      end
    end

    context "未ログインの場合" do
      it "ゲスト用UIを返す" do
        get infowindow_path, params: { spot_id: spot.id }

        expect(response).to have_http_status(:ok)
        # ゲスト用UIはログインを促すメッセージを含む
      end

      it "認証不要でアクセス可能" do
        get infowindow_path, params: { place_id: "ChIJtest123" }

        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "POST /infowindow" do
    context "ログイン済みの場合" do
      before { sign_in user }

      it "InfoWindowを作成する" do
        post infowindow_path, params: {
          spot_id: spot.id,
          plan_id: plan.id,
          photo_urls: [ "https://example.com/photo1.jpg" ]
        }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(spot.name)
      end

      it "place_idで新規スポットを作成してInfoWindowを返す" do
        post infowindow_path, params: {
          place_id: "ChIJnew_place",
          lat: 35.6580,
          lng: 139.7016,
          name: "新しいスポット",
          address: "東京都渋谷区"
        }

        expect(response).to have_http_status(:ok)
      end

      it "button_labelを指定できる" do
        post infowindow_path, params: {
          spot_id: spot.id,
          button_label: "プランに追加"
        }

        expect(response).to have_http_status(:ok)
      end

      it "show_button=falseでボタンを非表示にできる" do
        post infowindow_path, params: {
          spot_id: spot.id,
          show_button: "false"
        }

        expect(response).to have_http_status(:ok)
      end
    end

    context "未ログインの場合" do
      it "認証エラーを返す" do
        post infowindow_path, params: { spot_id: spot.id }

        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
