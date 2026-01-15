class AddParentIdToGenres < ActiveRecord::Migration[8.1]
  # 親ジャンル → 細分化ジャンルのマッピング
  PARENT_CHILD_MAP = {
    "gourmet" => %w[
      ramen sushi yakiniku curry washoku udon_soba tempura tonkatsu yakitori
      seafood okonomiyaki gyudon italian french steak hamburger pizza
      chinese gyoza korean thai indian vietnamese fastfood
    ],
    "cafe" => %w[
      kissaten pancake cake_shop bakery tapioca donut icecream crepe wagashi
    ],
    "bar" => %w[
      izakaya snack_bar pub
    ],
    "sightseeing" => %w[
      world_heritage night_view power_spot old_townscape market shopping_street
      dam bridge lighthouse ropeway factory_tour science_museum memorial_hall
    ]
  }.freeze

  def up
    Genre.reset_column_information
    add_column :genres, :parent_id, :bigint
    add_index :genres, :parent_id
    add_foreign_key :genres, :genres, column: :parent_id

    # 親子関係を設定
    PARENT_CHILD_MAP.each do |parent_slug, child_slugs|
      parent = Genre.find_by(slug: parent_slug)
      next unless parent

      Genre.where(slug: child_slugs).update_all(parent_id: parent.id)
    end
  end

  def down
    remove_foreign_key :genres, column: :parent_id
    remove_index :genres, :parent_id
    remove_column :genres, :parent_id
  end
end
