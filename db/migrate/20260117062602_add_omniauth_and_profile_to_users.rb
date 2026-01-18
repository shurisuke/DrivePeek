class AddOmniauthAndProfileToUsers < ActiveRecord::Migration[8.1]
  def change
    # SNS認証用
    add_column :users, :provider, :string
    add_column :users, :uid, :string
    add_index :users, [:provider, :uid], unique: true

    # プロフィール情報（コメント機能用）
    add_column :users, :birth_date, :date
    add_column :users, :gender, :integer, default: 0
    add_column :users, :residence, :string
  end
end
