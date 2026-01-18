class RemoveNameFromUsers < ActiveRecord::Migration[8.1]
  def change
    remove_column :users, :name, :string
  end
end
