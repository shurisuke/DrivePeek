# frozen_string_literal: true

require "rails_helper"

RSpec.describe "PlanSpots", type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:plan) { create(:plan, user: user) }
  let(:other_plan) { create(:plan, user: other_user) }
  let(:spot) { create(:spot) }
  let(:turbo_stream_headers) { { "Accept" => "text/vnd.turbo-stream.html" } }

  describe "POST /plans/:plan_id/plan_spots" do
    context "ログイン済み・自分のプランの場合" do
      before { sign_in user }

      it "スポットをプランに追加する" do
        expect {
          post plan_plan_spots_path(plan), params: { spot_id: spot.id }, headers: turbo_stream_headers
        }.to change(PlanSpot, :count).by(1)

        expect(response).to have_http_status(:ok)
      end

      it "追加されたplan_spotを作成する" do
        post plan_plan_spots_path(plan), params: { spot_id: spot.id }, headers: turbo_stream_headers

        plan_spot = plan.reload.plan_spots.last
        expect(plan_spot).to be_present
        expect(plan_spot.spot_id).to eq(spot.id)
      end

      it "存在しないスポットの場合404を返す" do
        post plan_plan_spots_path(plan), params: { spot_id: 99999 }, as: :json

        expect(response).to have_http_status(:not_found)
      end

      it "Turbo Stream形式でレスポンスを返す" do
        post plan_plan_spots_path(plan),
             params: { spot_id: spot.id },
             headers: turbo_stream_headers

        expect(response).to have_http_status(:ok)
        expect(response.content_type).to include("text/vnd.turbo-stream.html")
      end
    end

    context "他人のプランの場合" do
      before { sign_in user }

      it_behaves_like "他人のリソースへのアクセス拒否",
                      :post,
                      -> { plan_plan_spots_path(other_plan) },
                      params: { spot_id: 1 }
    end

    it_behaves_like "要認証エンドポイント",
                    :post,
                    -> { plan_plan_spots_path(plan) },
                    params: { spot_id: 1 }
  end

  describe "PATCH /plans/:plan_id/plan_spots/:id" do
    let!(:plan_spot) { create(:plan_spot, plan: plan, spot: spot, toll_used: false, memo: nil, stay_duration: 30) }
    let!(:other_plan_spot) { create(:plan_spot, plan: other_plan, spot: spot) }

    context "ログイン済み・自分のプランの場合" do
      before { sign_in user }

      it_behaves_like "PlanSpot属性更新", :toll_used, true
      it_behaves_like "PlanSpot属性更新", :toll_used, false
      it_behaves_like "PlanSpot属性更新", :memo, "ここでランチ"
      it_behaves_like "PlanSpot属性更新", :memo, ""
      it_behaves_like "PlanSpot属性更新", :stay_duration, 60
      it_behaves_like "PlanSpot属性更新", :stay_duration, 0
      it_behaves_like "PlanSpot属性をnilに更新", :stay_duration
    end

    context "他人のプランのplan_spotの場合" do
      before { sign_in user }

      it_behaves_like "他人のリソースへのアクセス拒否",
                      :patch,
                      -> { plan_plan_spot_path(other_plan, other_plan_spot) },
                      params: { toll_used: true }
    end

    it_behaves_like "要認証エンドポイント",
                    :patch,
                    -> { plan_plan_spot_path(plan, plan_spot) },
                    params: { toll_used: true }
  end

  describe "DELETE /plans/:plan_id/plan_spots/:id" do
    let!(:plan_spot) { create(:plan_spot, plan: plan, spot: spot) }
    let!(:other_plan_spot) { create(:plan_spot, plan: other_plan, spot: spot) }

    context "ログイン済み・自分のプランの場合" do
      before { sign_in user }

      it "スポットをプランから削除する" do
        expect {
          delete plan_plan_spot_path(plan, plan_spot), headers: turbo_stream_headers
        }.to change(PlanSpot, :count).by(-1)

        expect(response).to have_http_status(:ok)
      end

      it "HTML形式ではリダイレクトする" do
        delete plan_plan_spot_path(plan, plan_spot)

        expect(response).to redirect_to(edit_plan_path(plan))
      end
    end

    context "他人のプランの場合" do
      before { sign_in user }

      it "404エラーを返す" do
        delete plan_plan_spot_path(other_plan, other_plan_spot), headers: turbo_stream_headers
        expect(response).to have_http_status(:not_found)
      end

      it "スポットは削除されない" do
        expect {
          delete plan_plan_spot_path(other_plan, other_plan_spot), headers: turbo_stream_headers
        }.not_to change(PlanSpot, :count)
      end
    end

    it_behaves_like "要認証エンドポイント（リダイレクト）",
                    :delete,
                    -> { plan_plan_spot_path(plan, plan_spot) }
  end

  describe "POST /plans/:plan_id/plan_spots/adopt" do
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
          post plan_plan_spots_adopt_path(plan), params: { spots: spots_params }, headers: turbo_stream_headers
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

        post plan_plan_spots_adopt_path(plan), params: { spots: spots_params }, headers: turbo_stream_headers

        expect(plan.reload.plan_spots.count).to eq(2)
        expect(plan.plan_spots.pluck(:spot_id)).to match_array([ spot1.id, spot2.id ])
      end

      it "空のスポットリストは422を返す" do
        post plan_plan_spots_adopt_path(plan), params: { spots: [] }, as: :json

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "他人のプランの場合" do
      before { sign_in user }

      it_behaves_like "他人のリソースへのアクセス拒否",
                      :post,
                      -> { plan_plan_spots_adopt_path(other_plan) },
                      params: { spots: [ { spot_id: 1 } ] }
    end

    it_behaves_like "要認証エンドポイント",
                    :post,
                    -> { plan_plan_spots_adopt_path(plan) },
                    params: { spots: [ { spot_id: 1 } ] }
  end
end
