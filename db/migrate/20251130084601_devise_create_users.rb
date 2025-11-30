class DeviseCreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      ## 必須: 名前
      t.string :name, null: false

      ## Devise 標準認証用
      t.string :email,              null: false, default: ""
      t.string :encrypted_password, null: false, default: ""

      ## パスワードリセット用
      t.string   :reset_password_token
      t.datetime :reset_password_sent_at

      ## ログイン記録（Rememberable）
      t.datetime :remember_created_at

      ## Confirmable機能（メール再確認のためのカラム）
      t.string   :unconfirmed_email  # Only if using reconfirmable

      ## ステータス管理（enum用）
      t.integer :status, default: 0, null: false

      ## タイムスタンプ
      t.timestamps null: false
    end

    # インデックス
    add_index :users, :email, unique: true
    add_index :users, :reset_password_token, unique: true
  end
end
