# frozen_string_literal: true

require "rails_helper"

RSpec.describe Plan::Schedule, type: :model do
  describe "#initialize" do
    let(:plan) { create(:plan, user: create(:user)) }

    it "planを設定する" do
      schedule = described_class.new(plan)
      expect(schedule.plan).to eq(plan)
    end
  end

  describe "#recalculate!" do
    let(:user) { create(:user) }
    let(:plan) { create(:plan, user: user) }
    let(:spot1) { create(:spot) }
    let(:spot2) { create(:spot) }

    context "出発時間が設定されている場合" do
      before do
        start_point = create(:start_point,
                             plan: plan,
                             departure_time: Time.zone.local(2000, 1, 1, 9, 0),
                             move_time: 30)
        goal_point = create(:goal_point, plan: plan)
        plan.update!(start_point: start_point, goal_point: goal_point)

        create(:plan_spot, plan: plan, spot: spot1, position: 0, stay_duration: 45, move_time: 30)
        create(:plan_spot, plan: plan, spot: spot2, position: 1, stay_duration: 45, move_time: 30)
      end

      it "trueを返す" do
        schedule = described_class.new(plan.reload)
        expect(schedule.recalculate!).to be true
      end

      it "plan_spotsの到着時刻を計算する" do
        schedule = described_class.new(plan.reload)
        schedule.recalculate!

        # 出発9:00 + 移動30分 = 9:30到着
        ps1 = plan.plan_spots.order(:position).first
        expect(ps1.arrival_time).to be_present
        expect(ps1.arrival_time.strftime("%H:%M")).to eq("09:30")
      end

      it "plan_spotsの出発時刻を計算する" do
        schedule = described_class.new(plan.reload)
        schedule.recalculate!

        # 到着9:30 + 滞在45分 = 10:15出発
        ps1 = plan.plan_spots.order(:position).first
        expect(ps1.departure_time).to be_present
        expect(ps1.departure_time.strftime("%H:%M")).to eq("10:15")
      end

      it "2番目のスポットの時刻を計算する" do
        schedule = described_class.new(plan.reload)
        schedule.recalculate!

        ps2 = plan.plan_spots.order(:position).second
        # spot1出発10:15 + 移動30分 = 10:45到着
        expect(ps2.arrival_time.strftime("%H:%M")).to eq("10:45")
        # 到着10:45 + 滞在45分 = 11:30出発
        expect(ps2.departure_time.strftime("%H:%M")).to eq("11:30")
      end

      it "goal_pointの到着時刻を計算する" do
        schedule = described_class.new(plan.reload)
        schedule.recalculate!

        # spot2出発11:30 + 移動30分 = 12:00到着
        expect(plan.goal_point.arrival_time.strftime("%H:%M")).to eq("12:00")
      end

      it "計算順序が正しい（arrival < departure）" do
        schedule = described_class.new(plan.reload)
        schedule.recalculate!

        plan.plan_spots.each do |ps|
          expect(ps.departure_time).to be > ps.arrival_time
        end
      end
    end

    context "出発時間が未設定の場合" do
      before do
        plan.start_point.update!(departure_time: nil)
        create(:plan_spot, plan: plan, spot: spot1, position: 0)
      end

      it "trueを返す（計算スキップも成功扱い）" do
        schedule = described_class.new(plan.reload)
        expect(schedule.recalculate!).to be true
      end

      it "時刻を更新しない" do
        schedule = described_class.new(plan.reload)
        schedule.recalculate!

        ps1 = plan.plan_spots.first
        expect(ps1.arrival_time).to be_nil
      end
    end

    context "start_pointがない場合" do
      it "trueを返す（計算スキップも成功扱い）" do
        schedule = described_class.new(plan)
        expect(schedule.recalculate!).to be true
      end
    end
  end

  describe "DUMMY_DATE" do
    it "2000年1月1日である" do
      expect(described_class::DUMMY_DATE).to eq(Date.new(2000, 1, 1))
    end
  end

  describe "日付をまたぐ場合" do
    let(:user) { create(:user) }
    let(:plan) { create(:plan, user: user) }
    let(:spot) { create(:spot) }

    before do
      plan.start_point.update!(
        departure_time: Time.zone.local(2000, 1, 1, 23, 0),
        move_time: 90
      )
      create(:plan_spot, plan: plan, spot: spot, position: 0, stay_duration: 30)
    end

    it "24時間で丸め込まれる" do
      schedule = described_class.new(plan.reload)
      schedule.recalculate!

      ps = plan.plan_spots.first
      # 23:00 + 90分 = 24:30 → 00:30
      expect(ps.arrival_time.strftime("%H:%M")).to eq("00:30")
    end
  end
end
