# frozen_string_literal: true

require "rails_helper"

RSpec.describe Genre, type: :model do
  describe ".expand_family" do
    let!(:parent) { create(:genre, parent: nil) }
    let!(:child1) { create(:genre, parent: parent) }
    let!(:child2) { create(:genre, parent: parent) }

    it "親ジャンル指定時は子も含める" do
      result = Genre.expand_family([ parent.id ])

      expect(result).to include(parent.id, child1.id, child2.id)
    end

    it "子ジャンル指定時は親も含める" do
      result = Genre.expand_family([ child1.id ])

      expect(result).to include(parent.id, child1.id)
    end

    it "空配列は空を返す" do
      expect(Genre.expand_family([])).to eq([])
    end

    it "nilは空を返す" do
      expect(Genre.expand_family(nil)).to eq([])
    end

    it "重複を除去する" do
      result = Genre.expand_family([ parent.id, child1.id ])

      expect(result.uniq).to eq(result)
    end
  end

  describe ".grouped_by_category" do
    let!(:parent_genre) { create(:genre, name: "グルメ", category: "食べる", visible: true, parent: nil) }
    let!(:child_genre) { create(:genre, name: "ラーメン", category: "食べる", visible: true, parent: parent_genre) }
    let!(:hidden_genre) { create(:genre, name: "非表示", category: "食べる", visible: false, parent: nil) }

    it "カテゴリ別にグループ化する" do
      result = Genre.grouped_by_category

      expect(result).to have_key("食べる")
    end

    it "親ジャンルとその子を含む構造を返す" do
      result = Genre.grouped_by_category

      food_category = result["食べる"]
      expect(food_category.first[:genre]).to eq(parent_genre)
      expect(food_category.first[:children]).to include(child_genre)
    end

    it "非表示のジャンルは含まない" do
      result = Genre.grouped_by_category

      all_genres = result.values.flatten.map { |g| g[:genre] }
      expect(all_genres).not_to include(hidden_genre)
    end

    it "CATEGORY_ORDER順で並ぶ" do
      create(:genre, name: "温泉", category: "温まる", visible: true, parent: nil)

      result = Genre.grouped_by_category

      expect(result.keys).to eq(result.keys.sort_by { |k| Genre::CATEGORY_ORDER.index(k) || 999 })
    end
  end
end
