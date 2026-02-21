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
    it { should have_many(:suggestions).dependent(:destroy) }
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

    describe ".filter_by_cities" do
      let!(:tokyo_spot) { create(:spot, prefecture: "東京都", city: "渋谷区") }
      let!(:plan_with_tokyo) { create(:plan, user: user) }

      before do
        create(:plan_spot, plan: plan_with_tokyo, spot: tokyo_spot)
      end

      it "都道府県/市区町村形式で絞り込む" do
        expect(Plan.filter_by_cities([ "東京都/渋谷区" ])).to include(plan_with_tokyo)
      end

      it "都道府県のみでも絞り込む" do
        expect(Plan.filter_by_cities([ "東京都" ])).to include(plan_with_tokyo)
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

    describe ".within_circle" do
      let!(:center_spot) { create(:spot, lat: 35.6762, lng: 139.6503) }
      let!(:far_spot) { create(:spot, lat: 36.0, lng: 140.0) }
      let!(:plan_in_circle) { create(:plan, user: user) }
      let!(:plan_out_of_circle) { create(:plan, user: user) }

      before do
        create(:plan_spot, plan: plan_in_circle, spot: center_spot)
        create(:plan_spot, plan: plan_out_of_circle, spot: far_spot)
      end

      it "円内のスポットを含むプランを返す" do
        result = Plan.within_circle(35.6762, 139.6503, 5)
        expect(result).to include(plan_in_circle)
        expect(result).not_to include(plan_out_of_circle)
      end

      it "半径を広げると遠いプランも含まれる" do
        result = Plan.within_circle(35.6762, 139.6503, 100)
        expect(result).to include(plan_in_circle, plan_out_of_circle)
      end

      it "パラメータがnilの場合は全件返す" do
        result = Plan.within_circle(nil, 139.6503, 5)
        expect(result).to include(plan_in_circle, plan_out_of_circle)
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

  describe ".filter_by_genres" do
    let!(:genre) { create(:genre, slug: "gourmet") }
    let!(:spot_with_genre) { create(:spot) }
    let!(:spot_without_genre) { create(:spot) }
    let!(:plan_with_genre) { create(:plan, user: user) }
    let!(:plan_without_genre) { create(:plan, user: user) }

    before do
      create(:spot_genre, spot: spot_with_genre, genre: genre)
      create(:plan_spot, plan: plan_with_genre, spot: spot_with_genre)
      create(:plan_spot, plan: plan_without_genre, spot: spot_without_genre)
    end

    it "指定ジャンルのスポットを含むプランを返す" do
      result = Plan.filter_by_genres([ genre.id ])

      expect(result).to include(plan_with_genre)
      expect(result).not_to include(plan_without_genre)
    end

    it "空の配列の場合は全件返す" do
      result = Plan.filter_by_genres([])

      expect(result).to include(plan_with_genre, plan_without_genre)
    end
  end

  describe ".for_community" do
    let!(:active_user) { create(:user, status: :active) }
    let!(:genre1) { create(:genre, slug: "nature") }
    let!(:genre2) { create(:genre, slug: "gourmet") }
    let!(:spot1) { create(:spot, prefecture: "東京都", city: "渋谷区", lat: 35.6, lng: 139.7) }
    let!(:spot2) { create(:spot, prefecture: "東京都", city: "新宿区", lat: 35.7, lng: 139.8) }
    let!(:plan) { create(:plan, user: active_user, title: "テストプラン") }

    before do
      # スポットに複数ジャンルを設定
      create(:spot_genre, spot: spot1, genre: genre1)
      create(:spot_genre, spot: spot1, genre: genre2)
      create(:spot_genre, spot: spot2, genre: genre1)
      # プランに複数スポットを設定
      create(:plan_spot, plan: plan, spot: spot1, position: 1)
      create(:plan_spot, plan: plan, spot: spot2, position: 2)
    end

    context "フィルター + ソートの組み合わせ" do
      it "重複したIDを返さない（JOINによる行増殖を防ぐ）" do
        result = Plan.for_community(sort: "popular")
        ids = result.pluck(:id)

        expect(ids).to eq(ids.uniq)
      end

      it "キーワード検索 + ソートでエラーが発生しない" do
        expect {
          Plan.for_community(keyword: "テスト", sort: "popular").to_a
        }.not_to raise_error
      end

      it "ジャンル検索 + ソートでエラーが発生しない" do
        expect {
          Plan.for_community(genre_ids: [ genre1.id ], sort: "popular").to_a
        }.not_to raise_error
      end

      it "エリア検索 + ソートでエラーが発生しない" do
        expect {
          Plan.for_community(
            circle: { center_lat: 35.6, center_lng: 139.7, radius_km: 50 },
            sort: "popular"
          ).to_a
        }.not_to raise_error
      end

      it "全フィルター + ソートの組み合わせでエラーが発生しない" do
        expect {
          Plan.for_community(
            keyword: "テスト",
            genre_ids: [ genre1.id ],
            cities: [ "東京都/渋谷区" ],
            circle: { center_lat: 35.6, center_lng: 139.7, radius_km: 50 },
            sort: "popular"
          ).to_a
        }.not_to raise_error
      end
    end
  end

  describe "#copy_spots_from" do
    let(:source_plan) { create(:plan, user: user, title: "元のプラン") }
    let(:target_plan) { create(:plan, user: user, title: "") }
    let(:start_point) { create(:start_point, plan: target_plan) }
    let(:goal_point) { create(:goal_point, plan: target_plan) }
    let(:spots) { create_list(:spot, 2) }

    before do
      target_plan.update!(start_point: start_point, goal_point: goal_point)
      spots.each_with_index do |spot, i|
        create(:plan_spot, plan: source_plan, spot: spot, position: i + 1, stay_duration: 60)
      end
      stub_google_directions_api
    end

    it "source_planのスポットをコピーする" do
      target_plan.copy_spots_from(source_plan)

      expect(target_plan.plan_spots.count).to eq(2)
    end

    it "タイトルはコピーしない（プライバシー保護）" do
      target_plan.copy_spots_from(source_plan)

      expect(target_plan.reload.title).to eq("")
    end

    it "sourceがnilの場合は何もしない" do
      expect { target_plan.copy_spots_from(nil) }.not_to change { target_plan.plan_spots.count }
    end

    it "stay_durationもコピーする" do
      target_plan.copy_spots_from(source_plan)

      expect(target_plan.plan_spots.first.stay_duration).to eq(60)
    end
  end

  describe "#related_plans" do
    let!(:tokyo_spot) { create(:spot, prefecture: "東京都", city: "渋谷区") }
    let!(:osaka_spot) { create(:spot, prefecture: "大阪府", city: "大阪市") }
    let(:plan) { create(:plan, :with_spots, user: user) }
    let!(:related_plan) { create(:plan, user: create(:user, status: :active)) }
    let!(:unrelated_plan) { create(:plan, user: create(:user, status: :active)) }

    before do
      # planに東京のスポットを追加
      create(:plan_spot, plan: plan, spot: tokyo_spot)
      # related_planに東京のスポット2つを追加（with_multiple_spots条件を満たす）
      create(:plan_spot, plan: related_plan, spot: tokyo_spot)
      create(:plan_spot, plan: related_plan, spot: create(:spot, prefecture: "東京都", city: "渋谷区"))
      # unrelated_planには大阪のスポット2つを追加
      create(:plan_spot, plan: unrelated_plan, spot: osaka_spot)
      create(:plan_spot, plan: unrelated_plan, spot: create(:spot, prefecture: "大阪府", city: "大阪市"))
    end

    it "同じ市区町村のスポットを含むプランを返す" do
      result = plan.related_plans

      expect(result).to include(related_plan)
      expect(result).not_to include(unrelated_plan)
    end

    it "自分自身は含まない" do
      result = plan.related_plans

      expect(result).not_to include(plan)
    end
  end
end
