class MoveMemoFromUserSpotsToPlanSpots < ActiveRecord::Migration[8.1]
  def change
    # 1) plan_spots に memo を追加
    add_column :plan_spots, :memo, :text

    # 2) user_spots から memo を削除
    remove_column :user_spots, :memo, :text
  end
end
