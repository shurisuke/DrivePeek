# db/migrate/XXXXXXXXXXXXXX_change_move_distance_type_in_start_points.rb
class ChangeMoveDistanceTypeInStartPoints < ActiveRecord::Migration[8.1]
  def up
    change_column :start_points, :move_distance, :float, using: "move_distance::double precision"
  end

  def down
    change_column :start_points, :move_distance, :integer, using: "round(move_distance)::integer"
  end
end