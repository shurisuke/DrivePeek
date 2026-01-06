class UpdateWineryGenreName < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL
      UPDATE genres SET name = '酒屋・ワイナリー' WHERE slug = 'winery'
    SQL
  end

  def down
    execute <<~SQL
      UPDATE genres SET name = '酒蔵・ワイナリー' WHERE slug = 'winery'
    SQL
  end
end
