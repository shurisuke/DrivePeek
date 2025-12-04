class CreateStartPoints < ActiveRecord::Migration[8.1]
  def change
    create_table :start_points do |t|
      t.references :plan, null: false, foreign_key: true
      t.string :address
      t.float :lat
      t.float :lng
      t.datetime :departure_time
      t.string :prefecture
      t.string :city

      t.timestamps
    end

    # 都道府県や市区町村で検索する可能性があるならindex追加
    add_index :start_points, :prefecture
    add_index :start_points, :city
  end
end