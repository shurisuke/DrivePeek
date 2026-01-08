class CreateSpotGenres < ActiveRecord::Migration[8.1]
  def change
    create_table :spot_genres do |t|
      t.references :spot, null: false, foreign_key: true
      t.references :genre, null: false, foreign_key: true

      t.timestamps
    end

    add_index :spot_genres, [ :spot_id, :genre_id ], unique: true
  end
end
