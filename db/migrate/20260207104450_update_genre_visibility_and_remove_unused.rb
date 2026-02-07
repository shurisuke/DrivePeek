class UpdateGenreVisibilityAndRemoveUnused < ActiveRecord::Migration[8.0]
  def up
    # visible: false にするジャンル
    hide_names = %w[農園 ワイナリー カラオケ ゲームセンター 漫画喫茶 ゴルフ場 スキー場 スケート場 フットサル場]
    Genre.where(name: hide_names).update_all(visible: false, parent_id: nil)

    # 削除するジャンル
    delete_names = %w[運動場 スパ銭]
    Genre.where(name: delete_names).destroy_all
  end

  def down
    # 復元は手動で行う（データ依存のため）
    raise ActiveRecord::IrreversibleMigration
  end
end
