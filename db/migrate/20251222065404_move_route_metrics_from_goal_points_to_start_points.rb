# db/migrate/20251222065404_move_route_metrics_from_goal_points_to_start_points.rb
class MoveRouteMetricsFromGoalPointsToStartPoints < ActiveRecord::Migration[8.1]
  def up
    # 1) start_points に追加（toll_used は既にある前提なので追加しない）
    add_column :start_points, :move_time, :integer unless column_exists?(:start_points, :move_time)
    add_column :start_points, :move_distance, :integer unless column_exists?(:start_points, :move_distance)
    add_column :start_points, :move_cost, :integer unless column_exists?(:start_points, :move_cost)

    # 2) 既存データがある場合に備えて goal_points → start_points へコピー
    #    ※ start_points.toll_used は「カラムは既存」なので値だけ移す
    execute <<~SQL.squish
      UPDATE start_points
      SET
        move_time     = goal_points.move_time,
        move_distance = goal_points.move_distance,
        move_cost     = goal_points.move_cost,
        toll_used     = goal_points.toll_used
      FROM goal_points
      WHERE start_points.plan_id = goal_points.plan_id
    SQL

    # 3) goal_points から削除（存在する場合のみ）
    remove_column :goal_points, :move_time if column_exists?(:goal_points, :move_time)
    remove_column :goal_points, :move_distance if column_exists?(:goal_points, :move_distance)
    remove_column :goal_points, :move_cost if column_exists?(:goal_points, :move_cost)
    remove_column :goal_points, :toll_used if column_exists?(:goal_points, :toll_used)
  end

  def down
    # rollback 時：goal_points に戻す
    add_column :goal_points, :move_time, :integer unless column_exists?(:goal_points, :move_time)
    add_column :goal_points, :move_distance, :integer unless column_exists?(:goal_points, :move_distance)
    add_column :goal_points, :move_cost, :integer unless column_exists?(:goal_points, :move_cost)
    add_column :goal_points, :toll_used, :boolean unless column_exists?(:goal_points, :toll_used)

    execute <<~SQL.squish
      UPDATE goal_points
      SET
        move_time     = start_points.move_time,
        move_distance = start_points.move_distance,
        move_cost     = start_points.move_cost,
        toll_used     = start_points.toll_used
      FROM start_points
      WHERE goal_points.plan_id = start_points.plan_id
    SQL

    remove_column :start_points, :move_time if column_exists?(:start_points, :move_time)
    remove_column :start_points, :move_distance if column_exists?(:start_points, :move_distance)
    remove_column :start_points, :move_cost if column_exists?(:start_points, :move_cost)
    # toll_used は元から start_points にある前提なので down でも消さない
  end
end
