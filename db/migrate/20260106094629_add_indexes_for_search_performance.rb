class AddIndexesForSearchPerformance < ActiveRecord::Migration[8.1]
  def change
    # ソート用（for_community scopeのorder(updated_at: :desc)）
    add_index :plans, :updated_at

    # publicly_visible scope用（where(users: { status: :active })）
    add_index :users, :status
  end
end
