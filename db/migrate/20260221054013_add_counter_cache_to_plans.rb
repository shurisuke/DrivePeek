class AddCounterCacheToPlans < ActiveRecord::Migration[8.1]
  def change
    add_column :plans, :favorite_plans_count, :integer, default: 0, null: false
    add_column :plans, :plan_spots_count, :integer, default: 0, null: false

    reversible do |dir|
      dir.up do
        Plan.find_each do |plan|
          Plan.reset_counters(plan.id, :favorite_plans, :plan_spots)
        end
      end
    end
  end
end
