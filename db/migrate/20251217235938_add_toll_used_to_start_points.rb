class AddTollUsedToStartPoints < ActiveRecord::Migration[8.1]
  def change
    add_column :start_points, :toll_used, :boolean, null: false, default: false
  end
end