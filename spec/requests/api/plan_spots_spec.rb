# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::PlanSpots", type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:plan) { create(:plan, user: user) }
  let(:spot) { create(:spot) }
  let(:turbo_stream_headers) { { "Accept" => "text/vnd.turbo-stream.html" } }

  before do
    stub_google_geocoding_api
    stub_google_directions_api
  end

  describe "POST /api/plan_spots" do
    context "ログイン済み・自分のプランの場合" do
      before { sign_in user }

      it "スポットをプランに追加する" do
        expect {
          post api_plan_spots_path, params: { plan_id: plan.id, spot_id: spot.id }, headers: turbo_stream_headers
        }.to change(PlanSpot, :count).by(1)

        expect(response).to have_http_status(:ok)
      end

      it "追加されたplan_spotを作成する" do
        post api_plan_spots_path, params: { plan_id: plan.id, spot_id: spot.id }, headers: turbo_stream_headers

        plan_spot = plan.reload.plan_spots.last
        expect(plan_spot).to be_present
        expect(plan_spot.spot_id).to eq(spot.id)
      end

      it "存在しないスポットの場合404を返す" do
        post api_plan_spots_path, params: { plan_id: plan.id, spot_id: 99999 }, as: :json

        expect(response).to have_http_status(:not_found)
      end

      it "Turbo Stream形式でレスポンスを返す" do
        post api_plan_spots_path,
             params: { plan_id: plan.id, spot_id: spot.id },
             headers: turbo_stream_headers

        expect(response).to have_http_status(:ok)
        expect(response.content_type).to include("text/vnd.turbo-stream.html")
      end
    end

    context "他人のプランの場合" do
      let(:other_plan) { create(:plan, user: other_user) }
      before { sign_in user }

      it "404エラーを返す" do
        post api_plan_spots_path, params: { plan_id: other_plan.id, spot_id: spot.id }, as: :json
        expect(response).to have_http_status(:not_found)
      end
    end

    context "未ログインの場合" do
      it "401エラーを返す" do
        post api_plan_spots_path, params: { plan_id: plan.id, spot_id: spot.id }, as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "PATCH /api/plan_spots/:id (update統合エンドポイント)" do
    let!(:plan_spot) { create(:plan_spot, plan: plan, spot: spot, toll_used: false, memo: nil, stay_duration: 30) }

    context "ログイン済み・自分のプランの場合" do
      before { sign_in user }

      describe "toll_used更新" do
        it "有料道路設定をtrueに更新する" do
          patch api_plan_spot_path(plan_spot),
                params: { toll_used: true },
                headers: turbo_stream_headers

          expect(response).to have_http_status(:ok)
          expect(plan_spot.reload.toll_used).to be true
        end

        it "有料道路設定をfalseに更新する" do
          plan_spot.update!(toll_used: true)

          patch api_plan_spot_path(plan_spot),
                params: { toll_used: false },
                headers: turbo_stream_headers

          expect(response).to have_http_status(:ok)
          expect(plan_spot.reload.toll_used).to be false
        end
      end

      describe "memo更新" do
        it "メモを更新する" do
          patch api_plan_spot_path(plan_spot),
                params: { memo: "ここでランチ" },
                headers: turbo_stream_headers

          expect(response).to have_http_status(:ok)
          expect(plan_spot.reload.memo).to eq("ここでランチ")
        end

        it "メモを空にする" do
          plan_spot.update!(memo: "既存メモ")

          patch api_plan_spot_path(plan_spot),
                params: { memo: "" },
                headers: turbo_stream_headers

          expect(response).to have_http_status(:ok)
          expect(plan_spot.reload.memo).to eq("")
        end
      end

      describe "stay_duration更新" do
        it "滞在時間を更新する" do
          patch api_plan_spot_path(plan_spot),
                params: { stay_duration: 60 },
                headers: turbo_stream_headers

          expect(response).to have_http_status(:ok)
          expect(plan_spot.reload.stay_duration).to eq(60)
        end

        it "滞在時間を0にする" do
          patch api_plan_spot_path(plan_spot),
                params: { stay_duration: 0 },
                headers: turbo_stream_headers

          expect(response).to have_http_status(:ok)
          expect(plan_spot.reload.stay_duration).to eq(0)
        end

        it "滞在時間を空にする（nil）" do
          patch api_plan_spot_path(plan_spot),
                params: { stay_duration: "" },
                headers: turbo_stream_headers

          expect(response).to have_http_status(:ok)
          expect(plan_spot.reload.stay_duration).to be_nil
        end
      end

      it "Turbo Stream形式でレスポンスを返す" do
        patch api_plan_spot_path(plan_spot),
              params: { toll_used: true },
              headers: turbo_stream_headers

        expect(response).to have_http_status(:ok)
        expect(response.content_type).to include("text/vnd.turbo-stream.html")
      end
    end

    context "他人のプランのplan_spotの場合" do
      let(:other_plan) { create(:plan, user: other_user) }
      let!(:other_plan_spot) { create(:plan_spot, plan: other_plan, spot: spot) }
      before { sign_in user }

      it "404エラーを返す" do
        patch api_plan_spot_path(other_plan_spot),
              params: { toll_used: true },
              as: :json

        expect(response).to have_http_status(:not_found)
      end
    end

    context "未ログインの場合" do
      it "401エラーを返す" do
        patch api_plan_spot_path(plan_spot),
              params: { toll_used: true },
              as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "POST /api/plan_spots/adopt" do
    let!(:spot1) { create(:spot) }
    let!(:spot2) { create(:spot) }
    let!(:spot3) { create(:spot) }

    context "ログイン済み・自分のプランの場合" do
      before { sign_in user }

      it "複数スポットを一括追加する" do
        spots_params = [
          { spot_id: spot1.id },
          { spot_id: spot2.id },
          { spot_id: spot3.id }
        ]

        expect {
          post adopt_api_plan_spots_path, params: { plan_id: plan.id, spots: spots_params }, headers: turbo_stream_headers
        }.to change { plan.plan_spots.count }.by(3)

        expect(response).to have_http_status(:ok)
      end

      it "既存スポットを置換する" do
        existing_spot = create(:spot)
        create(:plan_spot, plan: plan, spot: existing_spot)

        spots_params = [
          { spot_id: spot1.id },
          { spot_id: spot2.id }
        ]

        post adopt_api_plan_spots_path, params: { plan_id: plan.id, spots: spots_params }, headers: turbo_stream_headers

        expect(plan.reload.plan_spots.count).to eq(2)
        expect(plan.plan_spots.pluck(:spot_id)).to match_array([ spot1.id, spot2.id ])
      end

      it "空のスポットリストは422を返す" do
        post adopt_api_plan_spots_path, params: { plan_id: plan.id, spots: [] }, as: :json

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "Turbo Stream形式でレスポンスを返す" do
        spots_params = [ { spot_id: spot1.id } ]

        post adopt_api_plan_spots_path,
             params: { plan_id: plan.id, spots: spots_params },
             headers: turbo_stream_headers

        expect(response).to have_http_status(:ok)
        expect(response.content_type).to include("text/vnd.turbo-stream.html")
      end
    end

    context "他人のプランの場合" do
      let(:other_plan) { create(:plan, user: other_user) }
      before { sign_in user }

      it "404エラーを返す" do
        spots_params = [ { spot_id: spot1.id } ]

        post adopt_api_plan_spots_path, params: { plan_id: other_plan.id, spots: spots_params }, as: :json
        expect(response).to have_http_status(:not_found)
      end
    end

    context "未ログインの場合" do
      it "401エラーを返す" do
        spots_params = [ { spot_id: spot1.id } ]

        post adopt_api_plan_spots_path, params: { plan_id: plan.id, spots: spots_params }, as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
