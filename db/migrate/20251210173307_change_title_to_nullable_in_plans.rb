class ChangeTitleToNullableInPlans < ActiveRecord::Migration[7.1] # ←Railsのバージョンに合わせて
  def change
    change_column_null :plans, :title, true
  end
end
