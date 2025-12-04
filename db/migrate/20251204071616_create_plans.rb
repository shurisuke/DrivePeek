class CreatePlans < ActiveRecord::Migration[8.1]
  def change
    create_table :plans do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title, null: false
      t.integer :total_time, null: false, default: 0
      t.float :total_distance, null: false, default: 0.0
      t.integer :total_cost, null: false, default: 0

      t.timestamps
    end

    add_index :plans, :title
  end
end