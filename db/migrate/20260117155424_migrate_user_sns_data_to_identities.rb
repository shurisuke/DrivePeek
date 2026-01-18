class MigrateUserSnsDataToIdentities < ActiveRecord::Migration[8.1]
  def up
    # 既存のSNS連携データをidentitiesテーブルに移行
    execute <<-SQL
      INSERT INTO identities (user_id, provider, uid, created_at, updated_at)
      SELECT id, provider, uid, created_at, updated_at
      FROM users
      WHERE provider IS NOT NULL AND uid IS NOT NULL
    SQL

    # usersテーブルからprovider/uid列を削除
    remove_column :users, :provider
    remove_column :users, :uid
  end

  def down
    # provider/uid列を復元
    add_column :users, :provider, :string
    add_column :users, :uid, :string

    # identitiesテーブルからデータを戻す
    execute <<-SQL
      UPDATE users
      SET provider = identities.provider, uid = identities.uid
      FROM identities
      WHERE users.id = identities.user_id
    SQL
  end
end
