class AddPolylineToStartPointsAndPlanSpots < ActiveRecord::Migration[8.1]
  def change
    add_column :start_points, :polyline, :text
    add_column :plan_spots, :polyline, :text
  end
end
