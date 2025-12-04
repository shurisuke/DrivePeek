class CreateLikeSpots < ActiveRecord::Migration[8.1]
  def change
    create_table :like_spots do |t|
      t.references :user, null: false, foreign_key: true
      t.references :spot, null: false, foreign_key: true

      t.timestamps
    end

    # 同じユーザーが同じスポットを複数回お気に入りできないように制限
    add_index :like_spots, [ :user_id, :spot_id ], unique: true
  end
end
