# frozen_string_literal: true

class AddCategoryAndVisibleToGenres < ActiveRecord::Migration[7.1]
  def up
    # 1. カラムを追加
    add_column :genres, :category, :string
    add_column :genres, :visible, :boolean, default: true, null: false

    # 2. 新ジャンルを追加
    create_genre("sauna", "サウナ")
    create_genre("gym", "ジム")
    create_genre("bowling", "ボウリング場")

    # 3. アクティビティ → アクティビティ施設に名前変更
    Genre.find_by(slug: "activity")&.update!(name: "アクティビティ施設")

    # 4. カテゴリと順番を設定
    position = 0

    # 食べる
    set_genre("gourmet", "食べる", position += 1, true)
    set_genre("cafe", "食べる", position += 1, true)
    set_genre("bar", "食べる", position += 1, true)

    # 見る
    set_genre("sightseeing", "見る", position += 1, true)
    set_genre("castle_historic", "見る", position += 1, true)
    set_genre("shrine_temple", "見る", position += 1, true)
    set_genre("art_gallery", "見る", position += 1, false)
    set_genre("museum", "見る", position += 1, false)
    set_genre("movie_theater", "見る", position += 1, false)

    # お風呂
    set_genre("onsen", "お風呂", position += 1, true)
    set_genre("sauna", "お風呂", position += 1, true)

    # 動物
    set_genre("zoo", "動物", position += 1, true)
    set_genre("aquarium", "動物", position += 1, true)

    # 自然
    set_genre("sea_coast", "自然", position += 1, true)
    set_genre("mountain", "自然", position += 1, true)
    set_genre("scenic_view", "自然", position += 1, true)
    set_genre("park", "自然", position += 1, true)
    set_genre("garden_flower", "自然", position += 1, true)
    set_genre("lake_waterfall", "自然", position += 1, true)

    # 遊ぶ
    set_genre("theme_park", "遊ぶ", position += 1, true)
    set_genre("activity", "遊ぶ", position += 1, true)
    set_genre("ski_resort", "遊ぶ", position += 1, true)
    set_genre("water_park", "遊ぶ", position += 1, true)
    set_genre("gym", "遊ぶ", position += 1, false)
    set_genre("bowling", "遊ぶ", position += 1, false)
    set_genre("golf_course", "遊ぶ", position += 1, true)

    # 買う
    set_genre("shopping", "買う", position += 1, true)
    set_genre("roadside_station", "買う", position += 1, true)
    set_genre("winery", "買う", position += 1, true)
    set_genre("liquor_store", "買う", position += 1, true)

    # 泊まる
    set_genre("accommodation", "泊まる", position += 1, true)
  end

  def down
    remove_column :genres, :category
    remove_column :genres, :visible
    Genre.where(slug: %w[sauna gym bowling]).destroy_all
    Genre.find_by(slug: "activity")&.update!(name: "アクティビティ")
  end

  private

  def create_genre(slug, name)
    Genre.create!(slug: slug, name: name, position: 999) unless Genre.exists?(slug: slug)
  end

  def set_genre(slug, category, position, visible)
    genre = Genre.find_by(slug: slug)
    genre&.update!(category: category, position: position, visible: visible)
  end
end
