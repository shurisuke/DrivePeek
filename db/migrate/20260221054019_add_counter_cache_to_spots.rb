class AddCounterCacheToSpots < ActiveRecord::Migration[8.1]
  def change
    add_column :spots, :favorite_spots_count, :integer, default: 0, null: false

    reversible do |dir|
      dir.up do
        Spot.find_each do |spot|
          Spot.reset_counters(spot.id, :favorite_spots)
        end
      end
    end
  end
end
