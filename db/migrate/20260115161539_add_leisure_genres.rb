# frozen_string_literal: true

class AddLeisureGenres < ActiveRecord::Migration[7.1]
  def up
    max_position = Genre.maximum(:position) || 0

    # アクティビティ系の後に追加
    activity = Genre.find_by(slug: "activity")
    base_position = activity ? activity.position : max_position

    create_genre("golf_course", "ゴルフ場", base_position + 1)
    create_genre("ski_resort", "スキー場", base_position + 2)
    create_genre("water_park", "プール", base_position + 3)
    create_genre("movie_theater", "映画館", base_position + 4)
  end

  def down
    Genre.where(slug: %w[golf_course ski_resort water_park movie_theater]).destroy_all
  end

  private

  def create_genre(slug, name, position)
    return if Genre.exists?(slug: slug)
    Genre.create!(slug: slug, name: name, position: position)
  end
end
