# frozen_string_literal: true

require "rails_helper"

RSpec.describe StartPoint do
  let(:user) { create(:user) }
  let(:plan) { create(:plan, user: user) }

  describe "validations" do
    it "lat, lng, addressが必須" do
      start_point = StartPoint.new(plan: plan)

      expect(start_point).not_to be_valid
      expect(start_point.errors[:lat]).to be_present
      expect(start_point.errors[:lng]).to be_present
      expect(start_point.errors[:address]).to be_present
    end

    it "有効なデータで保存できる" do
      start_point = StartPoint.new(
        plan: plan,
        lat: 35.6812,
        lng: 139.7671,
        address: "東京都千代田区"
      )

      expect(start_point).to be_valid
    end
  end

  describe ".build_from_location" do
    context "Geocoderが正常に結果を返す場合" do
      it "Geocoderの結果を使ってstart_pointを構築する" do
        # rails_helper.rbでスタブされている
        start_point = StartPoint.build_from_location(plan: plan, lat: 35.6812, lng: 139.7671)

        expect(start_point.plan).to eq(plan)
        expect(start_point.prefecture).to eq("東京都")
        expect(start_point.city).to eq("渋谷区")
        expect(start_point.town).to eq("渋谷")
        expect(start_point.departure_time).to eq(StartPoint::DEFAULT_DEPARTURE_TIME)
      end

      it "新規レコードとして作成される" do
        start_point = StartPoint.build_from_location(plan: plan, lat: 35.6812, lng: 139.7671)

        expect(start_point).to be_new_record
      end
    end

    context "Geocoderがnilを返す場合" do
      before do
        allow(GoogleApi::Geocoder).to receive(:reverse).and_return(nil)
      end

      it "フォールバック値（東京駅）を使用する" do
        start_point = StartPoint.build_from_location(plan: plan, lat: 0, lng: 0)

        expect(start_point.lat).to eq(StartPoint::FALLBACK_LOCATION[:lat])
        expect(start_point.lng).to eq(StartPoint::FALLBACK_LOCATION[:lng])
        expect(start_point.address).to eq(StartPoint::FALLBACK_LOCATION[:address])
      end
    end
  end

  describe "#route_affecting_changes?" do
    let(:start_point) do
      create(:start_point, plan: plan, lat: 35.0, lng: 139.0, address: "東京都")
    end

    context "lat/lng/address/toll_usedが変更された場合" do
      it "latが変更されたらtrueを返す" do
        start_point.update!(lat: 36.0)
        expect(start_point.route_affecting_changes?).to be true
      end

      it "lngが変更されたらtrueを返す" do
        start_point.update!(lng: 140.0)
        expect(start_point.route_affecting_changes?).to be true
      end

      it "addressが変更されたらtrueを返す" do
        start_point.update!(address: "大阪府")
        expect(start_point.route_affecting_changes?).to be true
      end

      it "toll_usedが変更されたらtrueを返す" do
        start_point.update!(toll_used: true)
        expect(start_point.route_affecting_changes?).to be true
      end
    end

    context "経路に影響しない属性が変更された場合" do
      it "falseを返す" do
        start_point.touch
        expect(start_point.route_affecting_changes?).to be false
      end
    end
  end

  describe "#schedule_affecting_changes?" do
    let(:start_point) do
      create(:start_point, plan: plan, lat: 35.0, lng: 139.0, address: "東京都")
    end

    context "departure_timeが変更された場合" do
      it "trueを返す" do
        start_point.update!(departure_time: Time.zone.local(2000, 1, 1, 10, 0))
        expect(start_point.schedule_affecting_changes?).to be true
      end
    end

    context "他の属性が変更された場合" do
      it "falseを返す" do
        start_point.update!(lat: 36.0)
        expect(start_point.schedule_affecting_changes?).to be false
      end
    end
  end

  describe "#short_address" do
    let(:start_point) do
      create(:start_point, plan: plan, lat: 35.0, lng: 139.0, address: "東京都渋谷区渋谷1-1-1")
    end

    it "prefecture + city + town を返す" do
      # rails_helper.rbのスタブにより prefecture="東京都", city="渋谷区", town="渋谷"
      expect(start_point.short_address).to eq("東京都渋谷区渋谷")
    end
  end

  describe "geocode_if_needed (before_save callback)" do
    context "lat/lngが変更された場合" do
      let(:start_point) do
        create(:start_point, plan: plan, lat: 35.0, lng: 139.0, address: "東京都")
      end

      it "Geocoderを呼び出してprefecture/city/townを更新する" do
        # rails_helper.rbでスタブ済み、呼び出しを検証
        expect(GoogleApi::Geocoder).to receive(:reverse).with(lat: 36.0, lng: 140.0).and_return({
          lat: 36.0, lng: 140.0, address: "新住所", prefecture: "新県", city: "新市", town: "新町"
        })

        start_point.update!(lat: 36.0, lng: 140.0)

        expect(start_point.prefecture).to eq("新県")
        expect(start_point.city).to eq("新市")
        expect(start_point.town).to eq("新町")
      end
    end

    context "prefecture/city/townが未設定の場合" do
      it "Geocoderを呼び出して補完する" do
        # rails_helper.rbのスタブが使われる
        start_point = StartPoint.new(
          plan: plan,
          lat: 35.0,
          lng: 139.0,
          address: "テスト住所"
        )

        start_point.save!

        # スタブにより prefecture="東京都", city="渋谷区", town="渋谷"
        expect(start_point.prefecture).to eq("東京都")
        expect(start_point.city).to eq("渋谷区")
        expect(start_point.town).to eq("渋谷")
      end
    end

    context "Geocoderがnilを返す場合" do
      before do
        allow(GoogleApi::Geocoder).to receive(:reverse).and_return(nil)
      end

      it "prefecture/city/townは更新されない" do
        start_point = StartPoint.new(
          plan: plan,
          lat: 35.0,
          lng: 139.0,
          address: "テスト住所",
          prefecture: "元の県",
          city: "元の市",
          town: "元の町"
        )

        start_point.save!
        expect(start_point.prefecture).to eq("元の県")
        expect(start_point.city).to eq("元の市")
        expect(start_point.town).to eq("元の町")
      end
    end
  end

  describe "FALLBACK_LOCATION" do
    it "東京駅の座標を持つ" do
      expect(StartPoint::FALLBACK_LOCATION[:lat]).to eq(35.681236)
      expect(StartPoint::FALLBACK_LOCATION[:lng]).to eq(139.767125)
      expect(StartPoint::FALLBACK_LOCATION[:address]).to include("千代田区")
    end
  end

  describe "DEFAULT_DEPARTURE_TIME" do
    it "09:00を返す" do
      expect(StartPoint::DEFAULT_DEPARTURE_TIME.hour).to eq(9)
      expect(StartPoint::DEFAULT_DEPARTURE_TIME.min).to eq(0)
    end
  end
end
