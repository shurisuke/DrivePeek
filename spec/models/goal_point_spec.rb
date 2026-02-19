# frozen_string_literal: true

require "rails_helper"

RSpec.describe GoalPoint do
  let(:user) { create(:user) }
  let(:plan) { create(:plan, user: user) }

  describe "validations" do
    it "lat, lng, addressが必須" do
      goal_point = GoalPoint.new(plan: plan)

      expect(goal_point).not_to be_valid
      expect(goal_point.errors[:lat]).to be_present
      expect(goal_point.errors[:lng]).to be_present
      expect(goal_point.errors[:address]).to be_present
    end

    it "有効なデータで保存できる" do
      goal_point = GoalPoint.new(
        plan: plan,
        lat: 35.6812,
        lng: 139.7671,
        address: "東京都千代田区"
      )

      expect(goal_point).to be_valid
    end
  end

  describe ".build_from_start_point" do
    let(:start_point) do
      create(:start_point,
        plan: plan,
        lat: 35.6812,
        lng: 139.7671,
        address: "東京都千代田区丸の内"
      )
    end

    it "start_pointの座標と住所をコピーして作成する" do
      goal_point = GoalPoint.build_from_start_point(plan: plan, start_point: start_point)

      expect(goal_point.lat).to eq(35.6812)
      expect(goal_point.lng).to eq(139.7671)
      expect(goal_point.address).to eq("東京都千代田区丸の内")
      expect(goal_point.plan).to eq(plan)
    end

    it "新規レコードとして作成される" do
      goal_point = GoalPoint.build_from_start_point(plan: plan, start_point: start_point)

      expect(goal_point).to be_new_record
    end
  end

  describe "#route_affecting_changes?" do
    let(:goal_point) do
      create(:goal_point, plan: plan, lat: 35.0, lng: 139.0, address: "東京都")
    end

    context "lat/lng/addressが変更された場合" do
      it "trueを返す" do
        goal_point.update!(lat: 36.0)
        expect(goal_point.route_affecting_changes?).to be true
      end
    end

    context "他の属性が変更された場合" do
      it "falseを返す" do
        goal_point.touch
        expect(goal_point.route_affecting_changes?).to be false
      end
    end
  end

  describe "#schedule_affecting_changes?" do
    let(:goal_point) do
      create(:goal_point, plan: plan, lat: 35.0, lng: 139.0, address: "東京都")
    end

    it "常にfalseを返す" do
      goal_point.update!(lat: 36.0, address: "大阪府")
      expect(goal_point.schedule_affecting_changes?).to be false
    end
  end

  describe "#display_address" do
    # rails_helper.rbでGoogleApi::Geocoder.reverseがスタブされ、
    # 常に「東京都渋谷区渋谷」を返す
    let(:start_point) do
      create(:start_point,
        plan: plan,
        lat: 35.6812,
        lng: 139.7671,
        address: "東京都渋谷区渋谷1-1-1"
      )
    end

    context "出発地点と同じ座標の場合" do
      let(:goal_point) do
        create(:goal_point,
          plan: plan,
          lat: 35.6812,
          lng: 139.7671,
          address: "東京都渋谷区渋谷1-1-1"
        )
      end

      before { start_point }

      it "start_pointのshort_addressを返す" do
        # スタブにより prefecture="東京都", city="渋谷区", town="渋谷" となる
        expect(goal_point.display_address).to eq("東京都渋谷区渋谷")
      end
    end

    context "出発地点と異なる座標の場合" do
      let(:goal_point) do
        create(:goal_point,
          plan: plan,
          lat: 35.7100,
          lng: 139.8107,
          address: "東京都墨田区押上"
        )
      end

      before { start_point }

      it "自身のaddressを返す" do
        expect(goal_point.display_address).to eq("東京都墨田区押上")
      end
    end

    context "start_pointが存在しない場合" do
      let(:goal_point) do
        create(:goal_point,
          plan: plan,
          lat: 35.6812,
          lng: 139.7671,
          address: "東京都千代田区丸の内一丁目"
        )
      end

      it "自身のaddressを返す" do
        expect(goal_point.display_address).to eq("東京都千代田区丸の内一丁目")
      end
    end
  end
end
