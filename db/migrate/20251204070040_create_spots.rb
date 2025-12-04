class CreateSpots < ActiveRecord::Migration[8.1]
  def change
    create_table :spots do |t|
      t.string :name, null: false
      t.string :address, null: false
      t.float :lat, null: false
      t.float :lng, null: false
      t.string :place_id, null: false
      t.string :prefecture
      t.string :city
      t.string :photo_reference

      t.timestamps
    end

    add_index :spots, :place_id, unique: true
    add_index :spots, :prefecture
    add_index :spots, :city
  end
end