class CreateLikePlans < ActiveRecord::Migration[8.1]
  def change
    create_table :like_plans do |t|
      t.references :user, null: false, foreign_key: true
      t.references :plan, null: false, foreign_key: true

      t.timestamps
    end

    # 同じユーザーが同じプランを複数回お気に入りできないように制限
    add_index :like_plans, [ :user_id, :plan_id ], unique: true
  end
end
