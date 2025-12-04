class CreateUserSpots < ActiveRecord::Migration[8.1]
  def change
    create_table :user_spots do |t|
      t.references :user, null: false, foreign_key: true
      t.references :spot, null: false, foreign_key: true
      t.text :memo

      t.timestamps
    end

    add_index :user_spots, [:user_id, :spot_id], unique: true
  end
end