# frozen_string_literal: true

require "rails_helper"

RSpec.describe Plan::Route, type: :model do
  let(:user) { create(:user) }
  let(:plan) { create(:plan, user: user) }
  let(:start_point) { create(:start_point, plan: plan, lat: 35.6762, lng: 139.6503) }
  let(:goal_point) { create(:goal_point, plan: plan, lat: 35.6762, lng: 139.6503) }
  let(:spot1) { create(:spot, lat: 35.7, lng: 139.7) }
  let(:spot2) { create(:spot, lat: 35.8, lng: 139.8) }
  let!(:plan_spot1) { create(:plan_spot, plan: plan, spot: spot1, position: 0) }
  let!(:plan_spot2) { create(:plan_spot, plan: plan, spot: spot2, position: 1) }

  let(:route) { described_class.new(plan) }

  before do
    plan.update!(start_point: start_point, goal_point: goal_point)
    stub_google_directions_api
  end

  describe "#initialize" do
    it "planを設定する" do
      expect(route.plan).to eq(plan)
    end

    it "segment_cacheを空のHashで初期化する" do
      expect(route.segment_cache).to eq({})
    end

    it "api_call_countを0で初期化する" do
      expect(route.api_call_count).to eq(0)
    end
  end

  describe "#recalculate!" do
    context "start_pointがある場合" do
      it "trueを返す" do
        expect(route.recalculate!).to be true
      end

      it "各区間の経路データを保存する" do
        route.recalculate!

        start_point.reload
        expect(start_point.move_time).to be_present
        expect(start_point.move_distance).to be_present
      end

      it "同一区間はキャッシュを利用する" do
        route.recalculate!
        # 3区間: start→spot1, spot1→spot2, spot2→goal
        # キャッシュが効いているので3回のAPI呼び出し
        expect(route.api_call_count).to eq(3)
      end
    end

    context "start_pointがない場合" do
      before { plan.update!(start_point: nil) }

      it "falseを返す" do
        expect(route.recalculate!).to be false
      end
    end
  end

  describe "#recalculate_segments!" do
    context "空の配列が渡された場合" do
      it "trueを返す" do
        expect(route.recalculate_segments!([])).to be true
      end

      it "API呼び出しを行わない" do
        route.recalculate_segments!([])
        expect(route.api_call_count).to eq(0)
      end
    end
  end

  describe "FALLBACK_ROUTE_DATA" do
    it "正しい構造を持つ" do
      expect(described_class::FALLBACK_ROUTE_DATA).to eq({
        move_time: 0,
        move_distance: 0.0,
        polyline: nil
      })
    end
  end
end
