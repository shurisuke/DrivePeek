class CreateUserSpotTags < ActiveRecord::Migration[8.1]
  def change
    create_table :user_spot_tags do |t|
      t.references :user_spot, null: false, foreign_key: true
      t.references :tag, null: false, foreign_key: true

      t.timestamps
    end

    add_index :user_spot_tags, [:user_spot_id, :tag_id], unique: true
  end
end
