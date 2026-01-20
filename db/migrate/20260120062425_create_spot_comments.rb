class CreateSpotComments < ActiveRecord::Migration[8.1]
  def change
    create_table :spot_comments do |t|
      t.references :user, null: false, foreign_key: true
      t.references :spot, null: false, foreign_key: true
      t.text :body

      t.timestamps
    end
  end
end
