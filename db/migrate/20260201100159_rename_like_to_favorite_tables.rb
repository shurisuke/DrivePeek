class RenameLikeToFavoriteTables < ActiveRecord::Migration[8.1]
  def change
    rename_table :like_plans, :favorite_plans
    rename_table :like_spots, :favorite_spots
  end
end
