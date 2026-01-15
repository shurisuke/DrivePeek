# app/models/genre.rb
class Genre < ApplicationRecord
  # 親子関係
  belongs_to :parent, class_name: "Genre", optional: true
  has_many :children, class_name: "Genre", foreign_key: :parent_id, dependent: :nullify

  has_many :spot_genres, dependent: :destroy
  has_many :spots, through: :spot_genres

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :position, presence: true

  scope :ordered, -> { order(:position) }
  scope :roots, -> { where(parent_id: nil) }
  scope :visible_roots, -> { roots.where(visible: true) }

  # 親ジャンルかどうか
  def parent_genre?
    children.exists?
  end

  # 子ジャンルかどうか
  def child_genre?
    parent_id.present?
  end

  # 検索フィルタ用: カテゴリ別にグループ化されたジャンル構造を返す
  # 戻り値: { "食べる" => [{ genre: グルメ, children: [ラーメン, 寿司, ...] }, ...], ... }
  def self.grouped_by_category
    all_genres = includes(:children).ordered.to_a
    # トップレベルには親を持たない visible ジャンルのみ表示
    visible_root_genres = all_genres.select { |g| g.visible && g.parent_id.nil? }

    visible_root_genres.group_by(&:category).transform_values do |genres|
      genres.map do |genre|
        {
          genre: genre,
          children: genre.children.select(&:visible).sort_by(&:position)
        }
      end
    end
  end
end
