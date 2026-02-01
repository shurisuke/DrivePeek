class RemoveMoveCostColumns < ActiveRecord::Migration[8.1]
  def change
    remove_column :start_points, :move_cost, :integer
    remove_column :plan_spots, :move_cost, :integer, default: 0, null: false
    remove_column :plans, :total_cost, :integer, default: 0, null: false
  end
end
