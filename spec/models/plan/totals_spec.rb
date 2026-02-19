# frozen_string_literal: true

require "rails_helper"

RSpec.describe Plan::Totals, type: :model do
  let(:user) { create(:user) }

  describe "#total_distance" do
    let(:plan) { create(:plan, user: user) }
    let(:start_point) { create(:start_point, plan: plan, move_distance: 10.5) }
    let(:spot) { create(:spot) }
    let!(:plan_spot) { create(:plan_spot, plan: plan, spot: spot, move_distance: 15.3) }

    before { plan.update!(start_point: start_point) }

    it "合計走行距離を計算する" do
      expect(plan.total_distance).to eq(25.8)
    end
  end

  describe "#total_move_time" do
    let(:plan) { create(:plan, user: user) }
    let(:start_point) { create(:start_point, plan: plan, move_time: 30) }
    let(:spot) { create(:spot) }
    let!(:plan_spot) { create(:plan_spot, plan: plan, spot: spot, move_time: 45) }

    before { plan.update!(start_point: start_point) }

    it "合計移動時間を計算する" do
      expect(plan.total_move_time).to eq(75)
    end
  end

  describe "#formatted_move_time" do
    let(:plan) { create(:plan, user: user) }

    context "0分の場合" do
      it "「0分」を返す" do
        allow(plan).to receive(:total_move_time).and_return(0)
        expect(plan.formatted_move_time).to eq("0分")
      end
    end

    context "60分未満の場合" do
      it "分のみを返す" do
        allow(plan).to receive(:total_move_time).and_return(45)
        expect(plan.formatted_move_time).to eq("45分")
      end
    end

    context "60分以上の場合" do
      it "時間と分を返す" do
        allow(plan).to receive(:total_move_time).and_return(90)
        expect(plan.formatted_move_time).to eq("1時間30分")
      end
    end
  end
end
