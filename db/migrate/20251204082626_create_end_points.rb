class CreateEndPoints < ActiveRecord::Migration[8.1]
  def change
    create_table :end_points do |t|
      t.references :plan, null: false, foreign_key: true
      t.string :address
      t.float :lat
      t.float :lng
      t.datetime :arrival_time
      t.integer :move_time
      t.float :move_distance
      t.integer :move_cost
      t.boolean :toll_used, null: false, default: false

      t.timestamps
    end
  end
end
