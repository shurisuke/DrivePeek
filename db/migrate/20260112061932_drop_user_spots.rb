class DropUserSpots < ActiveRecord::Migration[8.1]
  def change
    drop_table :user_spots do |t|
      t.bigint :user_id, null: false
      t.bigint :spot_id, null: false
      t.timestamps

      t.index :user_id
      t.index :spot_id
      t.index [ :user_id, :spot_id ], unique: true
    end
  end
end
