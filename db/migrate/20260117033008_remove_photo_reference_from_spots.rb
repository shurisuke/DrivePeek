class RemovePhotoReferenceFromSpots < ActiveRecord::Migration[8.1]
  def change
    remove_column :spots, :photo_reference, :string
  end
end
