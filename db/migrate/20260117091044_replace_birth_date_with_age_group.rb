class ReplaceBirthDateWithAgeGroup < ActiveRecord::Migration[8.1]
  def change
    remove_column :users, :birth_date, :date
    add_column :users, :age_group, :integer
  end
end
