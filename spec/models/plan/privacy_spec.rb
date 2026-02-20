# frozen_string_literal: true

require "rails_helper"

RSpec.describe Plan, "プライバシー保護", type: :model do
  let(:user) { create(:user) }
  let(:plan) { create(:plan, :with_spots, user: user) }

  before do
    stub_all_google_apis
  end

  describe "#marker_data_for_public_view" do
    subject(:public_data) { plan.marker_data_for_public_view }

    it "出発地点を含まない" do
      expect(public_data).not_to have_key(:start_point)
    end

    it "帰宅地点を含まない" do
      expect(public_data).not_to have_key(:end_point)
      expect(public_data).not_to have_key(:goal_point)
    end

    it "スポットのみを含む" do
      expect(public_data).to have_key(:spots)
      expect(public_data[:spots]).to be_present
    end

    it "出発地点の緯度経度がJSONに含まれない" do
      start_lat = plan.start_point.lat.to_s[0, 6]
      expect(public_data.to_json).not_to include(start_lat)
    end
  end

  describe "#copy_spots_from" do
    let(:other_user) { create(:user) }
    let(:source_plan) { create(:plan, :with_spots, user: other_user, title: "コピー元プラン") }
    let(:new_plan) { create(:plan, user: user, title: "") }

    before do
      # ソースプランの出発地点を別の場所に設定（コピーされないことを確認するため）
      source_plan.start_point.update!(lat: 36.0, lng: 140.0, address: "ソースの自宅")
      source_plan.goal_point.update!(lat: 36.0, lng: 140.0, address: "ソースの自宅")

      new_plan.copy_spots_from(source_plan)
      new_plan.reload
    end

    it "出発地点をコピーしない" do
      expect(new_plan.start_point.lat).not_to eq(36.0)
      expect(new_plan.start_point.address).not_to eq("ソースの自宅")
    end

    it "帰宅地点をコピーしない" do
      expect(new_plan.goal_point.lat).not_to eq(36.0)
      expect(new_plan.goal_point.address).not_to eq("ソースの自宅")
    end

    it "タイトルをコピーしない" do
      expect(new_plan.title).to eq("")
    end

    it "スポットをコピーする" do
      expect(new_plan.spots.pluck(:id)).to match_array(source_plan.spots.pluck(:id))
    end
  end

  describe "#marker_data_for_edit" do
    subject(:edit_data) { plan.marker_data_for_edit }

    it "出発地点を含む（編集画面では必要）" do
      expect(edit_data).to have_key(:start_point)
    end

    it "帰宅地点を含む（編集画面では必要）" do
      expect(edit_data).to have_key(:end_point)
    end
  end
end
