class CreatePlanSpots < ActiveRecord::Migration[8.1]
  def change
    create_table :plan_spots do |t|
      t.references :plan, null: false, foreign_key: true
      t.references :spot, null: false, foreign_key: true
      t.integer :position, null: false
      t.integer :move_time, null: false, default: 0
      t.float :move_distance, null: false, default: 0
      t.integer :move_cost, null: false, default: 0
      t.boolean :toll_used, null: false, default: false
      t.datetime :arrival_time
      t.integer :stay_duration
      t.datetime :departure_time

      t.timestamps
    end

    # プラン内での同一スポット登録の重複防止
    add_index :plan_spots, [ :plan_id, :spot_id ], unique: true

    # plan内のpositionの重複防止
    add_index :plan_spots, [ :plan_id, :position ]
  end
end
