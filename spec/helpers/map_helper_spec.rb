# frozen_string_literal: true

require "rails_helper"

RSpec.describe MapHelper, type: :helper do
  describe "#place_type_labels" do
    it "空の場合は空配列を返す" do
      expect(helper.place_type_labels(nil)).to eq([])
      expect(helper.place_type_labels([])).to eq([])
    end

    it "認識できるtypeを日本語に変換する" do
      result = helper.place_type_labels([ "restaurant", "cafe" ])
      expect(result).to eq([ "レストラン", "カフェ" ])
    end

    it "最大2件まで返す" do
      result = helper.place_type_labels([ "restaurant", "cafe", "bar" ])
      expect(result.size).to eq(2)
    end

    it "認識できないtypeがあってもスキップする" do
      result = helper.place_type_labels([ "unknown_type", "restaurant" ])
      expect(result).to eq([ "レストラン" ])
    end

    it "すべて認識できない場合はスポットを返す" do
      result = helper.place_type_labels([ "unknown_type" ])
      expect(result).to eq([ "スポット" ])
    end
  end

  describe "#infowindow_default_zoom_scale" do
    it "デフォルトのズームスケールを返す" do
      expect(helper.infowindow_default_zoom_scale).to eq("md")
    end
  end

  describe "#infowindow_zoom_scales_json" do
    it "ズームスケール配列をJSON形式で返す" do
      result = helper.infowindow_zoom_scales_json
      parsed = JSON.parse(result)
      expect(parsed).to include("sm", "md", "lg", "xl")
    end
  end
end
