# frozen_string_literal: true

require "rails_helper"

RSpec.describe SpotImporter::GridGenerator do
  describe ".test_grids" do
    it "東京駅周辺の座標を返す" do
      grids = described_class.test_grids

      expect(grids).to eq([ { lat: 35.6812, lng: 139.7671 } ])
    end
  end

  describe ".kanto_grids" do
    it "グリッド配列を返す" do
      grids = described_class.kanto_grids

      expect(grids).to be_an(Array)
      expect(grids).not_to be_empty
    end

    it "各グリッドがlat/lng構造を持つ" do
      grids = described_class.kanto_grids

      grids.each do |grid|
        expect(grid).to have_key(:lat)
        expect(grid).to have_key(:lng)
        expect(grid[:lat]).to be_a(Float)
        expect(grid[:lng]).to be_a(Float)
      end
    end

    it "関東圏の範囲内に収まる" do
      grids = described_class.kanto_grids

      grids.each do |grid|
        expect(grid[:lat]).to be_between(34.9, 37.0)
        expect(grid[:lng]).to be_between(138.4, 140.9)
      end
    end
  end
end
