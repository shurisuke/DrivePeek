# frozen_string_literal: true

require "rails_helper"

RSpec.describe PlanSpot, type: :model do
  describe "associations" do
    it { should belong_to(:plan) }
    it { should belong_to(:spot) }
  end

  describe "validations" do
    let(:plan) { create(:plan) }
    let(:spot) { create(:spot) }

    describe "stay_duration" do
      it "nilは許可される" do
        plan_spot = build(:plan_spot, plan: plan, spot: spot, stay_duration: nil)
        expect(plan_spot).to be_valid
      end

      it "0は許可される" do
        plan_spot = build(:plan_spot, plan: plan, spot: spot, stay_duration: 0)
        expect(plan_spot).to be_valid
      end

      it "1200（20時間）は許可される" do
        plan_spot = build(:plan_spot, plan: plan, spot: spot, stay_duration: 1200)
        expect(plan_spot).to be_valid
      end

      it "1201以上は許可されない" do
        plan_spot = build(:plan_spot, plan: plan, spot: spot, stay_duration: 1201)
        expect(plan_spot).not_to be_valid
        expect(plan_spot.errors[:stay_duration]).to be_present
      end

      it "負の値は許可されない" do
        plan_spot = build(:plan_spot, plan: plan, spot: spot, stay_duration: -1)
        expect(plan_spot).not_to be_valid
        expect(plan_spot.errors[:stay_duration]).to be_present
      end
    end

    describe "spot_id uniqueness" do
      it "同一プラン内で同じスポットは追加できない" do
        create(:plan_spot, plan: plan, spot: spot)
        duplicate = build(:plan_spot, plan: plan, spot: spot)

        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:spot_id]).to include("は既にこのプランに追加されています")
      end

      it "異なるプランなら同じスポットを追加できる" do
        other_plan = create(:plan)
        create(:plan_spot, plan: plan, spot: spot)
        other_plan_spot = build(:plan_spot, plan: other_plan, spot: spot)

        expect(other_plan_spot).to be_valid
      end
    end
  end

  describe "MAX_STAY_DURATION" do
    it "1200分（20時間）である" do
      expect(PlanSpot::MAX_STAY_DURATION).to eq(1200)
    end
  end
end
