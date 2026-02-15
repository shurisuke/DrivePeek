class AddTownToSpotsAndStartPoints < ActiveRecord::Migration[8.1]
  def change
    add_column :spots, :town, :string
    add_column :start_points, :town, :string
  end
end
