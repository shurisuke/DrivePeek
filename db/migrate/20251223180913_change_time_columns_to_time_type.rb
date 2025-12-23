class ChangeTimeColumnsToTimeType < ActiveRecord::Migration[8.1]
  def up
    # start_points: 出発時間
    change_column :start_points, :departure_time, :time, using: "departure_time::time"

    # plan_spots: 到着時間・出発時間
    change_column :plan_spots, :arrival_time, :time, using: "arrival_time::time"
    change_column :plan_spots, :departure_time, :time, using: "departure_time::time"

    # goal_points: 到着時間
    change_column :goal_points, :arrival_time, :time, using: "arrival_time::time"
  end

  def down
    change_column :start_points, :departure_time, :datetime
    change_column :plan_spots, :arrival_time, :datetime
    change_column :plan_spots, :departure_time, :datetime
    change_column :goal_points, :arrival_time, :datetime
  end
end
