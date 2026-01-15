class AddFacilityGenre < ActiveRecord::Migration[8.1]
  def up
    Genre.reset_column_information
    max_position = Genre.maximum(:position) || 0
    Genre.create!(
      slug: "facility",
      name: "施設",
      category: "その他",
      visible: false,
      position: max_position + 1
    )
  end

  def down
    Genre.find_by(slug: "facility")&.destroy
  end
end
