# frozen_string_literal: true

require "rails_helper"

RSpec.describe PlansHelper, type: :helper do
  describe "#plan_title" do
    context "タイトルが設定されている場合" do
      let(:plan) { create(:plan, title: "海沿いドライブ") }

      it "設定されたタイトルを返す" do
        expect(helper.plan_title(plan)).to eq("海沿いドライブ")
      end
    end

    context "タイトルが未設定でスポットがない場合" do
      let(:plan) { create(:plan, title: nil) }

      it "未定のプランを返す" do
        expect(helper.plan_title(plan)).to eq("未定のプラン")
      end
    end

    context "タイトルが未設定でスポットが3つ以下の場合" do
      let(:plan) { create(:plan, title: nil) }

      before do
        create(:plan_spot, plan: plan, spot: create(:spot, city: "宇都宮市"))
        create(:plan_spot, plan: plan, spot: create(:spot, city: "日光市"))
      end

      it "市区町村名を連結したタイトルを返す" do
        expect(helper.plan_title(plan.reload)).to eq("宇都宮・日光ドライブ")
      end
    end

    context "タイトルが未設定でスポットが4つ以上の場合" do
      let(:plan) { create(:plan, title: nil) }

      before do
        create(:plan_spot, plan: plan, spot: create(:spot, city: "宇都宮市"))
        create(:plan_spot, plan: plan, spot: create(:spot, city: "日光市"))
        create(:plan_spot, plan: plan, spot: create(:spot, city: "鹿沼市"))
        create(:plan_spot, plan: plan, spot: create(:spot, city: "栃木市"))
      end

      it "最初の3つを連結し「ほか」を付ける" do
        expect(helper.plan_title(plan.reload)).to eq("宇都宮・日光・鹿沼ほかドライブ")
      end
    end
  end

  describe "#format_move_time" do
    it "1時間未満の場合は分のみ表示" do
      result = helper.format_move_time(45)
      expect(result).to include("45")
      expect(result).to include("分")
      expect(result).not_to include("時間")
    end

    it "1時間以上の場合は時間と分を表示" do
      result = helper.format_move_time(90)
      expect(result).to include("1")
      expect(result).to include("時間")
      expect(result).to include("30")
      expect(result).to include("分")
    end
  end

  describe "#format_distance" do
    it "nilの場合はnilを返す" do
      expect(helper.format_distance(nil)).to be_nil
    end

    it "10km以上は整数で表示" do
      expect(helper.format_distance(25.7)).to eq("25")
    end

    it "10km未満は小数点1桁で表示" do
      expect(helper.format_distance(5.5)).to eq("5.5")
    end

    it "小数点以下が0の場合は省略" do
      expect(helper.format_distance(5.0)).to eq("5")
    end
  end

  describe "#share_text_for_plan" do
    let(:plan) { create(:plan) }

    context "スポットがない場合" do
      it "空文字を返す" do
        expect(helper.share_text_for_plan(plan)).to eq("")
      end
    end

    context "スポットがある場合" do
      before do
        create(:plan_spot, plan: plan, spot: create(:spot, name: "東京タワー"), position: 1)
        create(:plan_spot, plan: plan, spot: create(:spot, name: "東京スカイツリー"), position: 2)
      end

      it "丸数字とスポット名を含む" do
        result = helper.share_text_for_plan(plan)
        expect(result).to include("① 東京タワー")
        expect(result).to include("② 東京スカイツリー")
      end
    end
  end

  describe "#google_maps_nav_url" do
    let(:plan) { create(:plan) }

    context "スポットがない場合" do
      it "nilを返す" do
        expect(helper.google_maps_nav_url(plan)).to be_nil
      end
    end

    context "スポットがある場合" do
      before do
        create(:plan_spot, plan: plan, spot: create(:spot, name: "目的地", place_id: "ChIJ123"), position: 1)
      end

      it "Google MapsのURLを返す" do
        url = helper.google_maps_nav_url(plan)
        expect(url).to include("google.com/maps/dir")
        expect(url).to include("destination")
      end
    end

    context "経由地がある場合" do
      before do
        create(:plan_spot, plan: plan, spot: create(:spot, name: "経由地"), position: 1)
        create(:plan_spot, plan: plan, spot: create(:spot, name: "目的地"), position: 2)
      end

      it "waypointsパラメータを含む" do
        url = helper.google_maps_nav_url(plan)
        expect(url).to include("waypoints")
      end
    end
  end

  describe "#format_selected_cities" do
    it "空の場合はエリアを返す" do
      expect(helper.format_selected_cities(nil)).to eq("エリア")
      expect(helper.format_selected_cities([])).to eq("エリア")
    end

    it "選択された市区町村名を返す" do
      cities = [ "栃木県/宇都宮市", "栃木県/日光市" ]
      result = helper.format_selected_cities(cities)
      expect(result).to include("宇都宮市")
      expect(result).to include("日光市")
    end

    it "全選択時は県名のみを返す" do
      cities = [ "栃木県/宇都宮市", "栃木県/日光市" ]
      cities_by_prefecture = { "栃木県" => [ "宇都宮市", "日光市" ] }
      result = helper.format_selected_cities(cities, cities_by_prefecture)
      expect(result).to eq("栃木県")
    end
  end

  describe "#format_selected_genres" do
    it "空の場合はジャンルを返す" do
      expect(helper.format_selected_genres(nil)).to eq("ジャンル")
      expect(helper.format_selected_genres([])).to eq("ジャンル")
    end

    it "選択されたジャンル名を返す" do
      genre1 = create(:genre, name: "カフェ")
      genre2 = create(:genre, name: "ラーメン")
      result = helper.format_selected_genres([ genre1.id, genre2.id ])
      expect(result).to include("カフェ")
      expect(result).to include("ラーメン")
    end

    it "親ジャンルの全子ジャンルが選択された場合は親名のみを返す" do
      parent = create(:genre, name: "グルメ")
      child1 = create(:genre, name: "ラーメン", parent: parent)
      child2 = create(:genre, name: "カフェ", parent: parent)

      genres_by_category = {
        "グルメ" => [
          { genre: parent, children: [ child1, child2 ] }
        ]
      }

      result = helper.format_selected_genres([ child1.id, child2.id ], genres_by_category)
      expect(result).to eq("グルメ")
    end
  end

  describe "#plan_preview_spots_json" do
    it "スポットデータをJSON形式で返す" do
      spots = [ { lat: 35.0, lng: 139.0, name: "テスト" } ]
      result = helper.plan_preview_spots_json(spots)
      expect(result).to be_a(String)
      expect(JSON.parse(result)).to be_an(Array)
    end
  end

  describe "#plan_preview_polylines_json" do
    let(:plan) { create(:plan) }

    it "ポリラインデータをJSON形式で返す" do
      result = helper.plan_preview_polylines_json(plan)
      expect(result).to be_a(String)
    end
  end

  describe "#format_move_time_simple" do
    it "1時間未満の場合は分のみ表示" do
      result = helper.format_move_time_simple(45)
      expect(result).to include("45")
      expect(result).to include("分")
      expect(result).not_to include("時間")
    end

    it "1時間以上の場合は時間と分を表示" do
      result = helper.format_move_time_simple(90)
      expect(result).to include("1")
      expect(result).to include("時間")
      expect(result).to include("30")
      expect(result).to include("分")
    end

    it "カスタムunit_classを適用できる" do
      result = helper.format_move_time_simple(90, unit_class: "custom-unit")
      expect(result).to include("custom-unit")
    end
  end
end
