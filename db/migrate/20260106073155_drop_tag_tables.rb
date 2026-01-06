class DropTagTables < ActiveRecord::Migration[8.1]
  def up
    drop_table :user_spot_tags, if_exists: true
    drop_table :tags, if_exists: true
  end

  def down
    create_table :tags do |t|
      t.string :tag_name, null: false
      t.timestamps
    end
    add_index :tags, :tag_name, unique: true

    create_table :user_spot_tags do |t|
      t.references :user_spot, null: false, foreign_key: true
      t.references :tag, null: false, foreign_key: true
      t.timestamps
    end
    add_index :user_spot_tags, %i[user_spot_id tag_id], unique: true
  end
end
