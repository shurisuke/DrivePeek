class RenameEndPointsToGoalPoints < ActiveRecord::Migration[8.1]
  def change
    rename_table :end_points, :goal_points
  end
end
