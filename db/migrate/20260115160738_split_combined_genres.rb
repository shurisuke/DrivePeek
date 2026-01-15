# frozen_string_literal: true

class SplitCombinedGenres < ActiveRecord::Migration[7.1]
  def up
    # 1. 既存ジャンル名を更新
    update_genre("museum", "博物館")  # 博物館・美術館 → 博物館
    update_genre("winery", "ワイナリー")  # 酒屋・ワイナリー → ワイナリー

    # 2. 新しいジャンルを追加
    max_position = Genre.maximum(:position) || 0

    # 美術館（博物館の次）
    museum = Genre.find_by(slug: "museum")
    create_genre("art_gallery", "美術館", museum ? museum.position + 1 : max_position + 1)

    # 動物園・水族館を分離
    zoo_aquarium = Genre.find_by(slug: "zoo_aquarium")
    if zoo_aquarium
      # 動物園に名前変更
      zoo_aquarium.update!(name: "動物園", slug: "zoo")
      # 水族館を追加
      create_genre("aquarium", "水族館", zoo_aquarium.position + 1)
    end

    # 酒屋・バーを追加
    winery = Genre.find_by(slug: "winery")
    winery_position = winery ? winery.position : max_position + 10
    create_genre("liquor_store", "酒屋", winery_position + 1)
    create_genre("bar", "バー", winery_position + 2)
  end

  def down
    # 追加したジャンルを削除
    Genre.where(slug: %w[art_gallery aquarium liquor_store bar]).destroy_all

    # 元の名前に戻す
    Genre.find_by(slug: "museum")&.update!(name: "博物館・美術館")
    Genre.find_by(slug: "zoo")&.update!(name: "動物園・水族館", slug: "zoo_aquarium")
    Genre.find_by(slug: "winery")&.update!(name: "酒屋・ワイナリー")
  end

  private

  def update_genre(slug, new_name)
    genre = Genre.find_by(slug: slug)
    genre&.update!(name: new_name)
  end

  def create_genre(slug, name, position)
    return if Genre.exists?(slug: slug)
    Genre.create!(slug: slug, name: name, position: position)
  end
end
