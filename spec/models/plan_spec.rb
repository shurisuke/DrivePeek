# frozen_string_literal: true

require "rails_helper"

RSpec.describe Plan, type: :model do
  let(:user) { create(:user) }

  describe "associations" do
    it { should belong_to(:user) }
    it { should have_many(:plan_spots).dependent(:destroy) }
    it { should have_many(:spots).through(:plan_spots) }
    it { should have_one(:start_point).dependent(:destroy) }
    it { should have_one(:goal_point).dependent(:destroy) }
    it { should have_many(:favorite_plans).dependent(:destroy) }
    it { should have_many(:liked_by_users).through(:favorite_plans).source(:user) }
    it { should have_many(:suggestion_logs).dependent(:destroy) }
  end

  describe "factory" do
    it "有効なファクトリを持つ" do
      expect(build(:plan, user: user)).to be_valid
    end

    it "with_spotsトレイトでスポット付きプランを作成できる" do
      plan = create(:plan, :with_spots, user: user)
      expect(plan.plan_spots.count).to eq(3)
    end
  end

  describe "scopes" do
    describe ".with_multiple_spots" do
      let!(:plan_with_spots) { create(:plan, :with_spots, user: user) }
      let!(:plan_without_spots) { create(:plan, user: user) }

      it "スポットが2つ以上あるプランのみ返す" do
        result = Plan.with_multiple_spots
        expect(result).to include(plan_with_spots)
        expect(result).not_to include(plan_without_spots)
      end
    end

    describe ".publicly_visible" do
      let!(:active_user) { create(:user, status: :active) }
      let!(:hidden_user) { create(:user, status: :hidden) }
      let!(:visible_plan) { create(:plan, user: active_user) }
      let!(:hidden_plan) { create(:plan, user: hidden_user) }

      it "アクティブユーザーのプランのみ返す" do
        result = Plan.publicly_visible
        expect(result).to include(visible_plan)
        expect(result).not_to include(hidden_plan)
      end
    end

    describe ".search_keyword" do
      let!(:plan) { create(:plan, user: user, title: "日光の旅") }

      it "タイトルで検索できる" do
        expect(Plan.search_keyword("日光")).to include(plan)
      end

      it "空のキーワードは全件返す" do
        expect(Plan.search_keyword("")).to include(plan)
        expect(Plan.search_keyword(nil)).to include(plan)
      end
    end

    describe ".liked_by" do
      let(:other_user) { create(:user) }
      let!(:liked_plan) { create(:plan, user: user) }
      let!(:unliked_plan) { create(:plan, user: user) }

      before { create(:favorite_plan, user: other_user, plan: liked_plan) }

      it "指定ユーザーがお気に入りしたプランのみ返す" do
        result = Plan.liked_by(other_user)
        expect(result).to include(liked_plan)
        expect(result).not_to include(unliked_plan)
      end

      it "nilの場合は空のRelationを返す" do
        expect(Plan.liked_by(nil)).to be_empty
      end
    end
  end

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

  describe ".create_with_location" do
    before do
      stub_google_geocoding_api
      stub_google_directions_api
    end

    it "位置情報からプランを作成する" do
      plan = Plan.create_with_location(user: user, lat: 35.6762, lng: 139.6503)

      expect(plan).to be_persisted
      expect(plan.start_point).to be_present
      expect(plan.goal_point).to be_present
    end

    it "start_pointに座標を設定する" do
      plan = Plan.create_with_location(user: user, lat: 35.6762, lng: 139.6503)

      expect(plan.start_point.lat).to eq(35.6762)
      expect(plan.start_point.lng).to eq(139.6503)
    end
  end

  describe "#adopt_spots!" do
    let(:plan) { create(:plan, user: user) }
    let(:start_point) { create(:start_point, plan: plan) }
    let(:goal_point) { create(:goal_point, plan: plan) }
    let(:spots) { create_list(:spot, 3) }

    before do
      plan.update!(start_point: start_point, goal_point: goal_point)
      stub_google_directions_api
    end

    it "スポットを一括設定する" do
      plan.adopt_spots!(spots.map(&:id))

      expect(plan.plan_spots.count).to eq(3)
    end

    it "既存のplan_spotsを削除する" do
      create(:plan_spot, plan: plan, spot: create(:spot))
      plan.adopt_spots!(spots.map(&:id))

      expect(plan.plan_spots.count).to eq(3)
    end
  end

  describe "#marker_data_for_edit" do
    let(:plan) { create(:plan, :with_spots, user: user) }
    let(:start_point) { create(:start_point, plan: plan, lat: 35.0, lng: 139.0) }
    let(:goal_point) { create(:goal_point, plan: plan, lat: 35.1, lng: 139.1) }

    before { plan.update!(start_point: start_point, goal_point: goal_point) }

    it "正しい構造を返す" do
      data = plan.marker_data_for_edit

      expect(data).to have_key(:start_point)
      expect(data).to have_key(:end_point)
      expect(data).to have_key(:spots)
    end

    it "start_pointの座標を含む" do
      data = plan.marker_data_for_edit

      expect(data[:start_point]).to eq({ lat: 35.0, lng: 139.0 })
    end
  end

  describe "#preview_data" do
    let(:plan) { create(:plan, :with_spots, user: user) }

    before do
      plan.plan_spots.each_with_index do |ps, i|
        ps.update!(polyline: "encoded_polyline_#{i}")
      end
    end

    it "spotsを含む" do
      data = plan.preview_data

      expect(data[:spots]).to be_present
      expect(data[:spots].size).to eq(plan.plan_spots.count)
    end

    it "polylinesを含む（最後のスポット除く）" do
      data = plan.preview_data

      # 最後のスポット→帰宅のポリラインは除外
      expect(data[:polylines].size).to eq(plan.plan_spots.count - 1)
    end
  end

end
