# app/models/genre.rb
class Genre < ApplicationRecord
  # カテゴリの表示順序
  CATEGORY_ORDER = %w[食べる 見る 買う お風呂 動物 自然 遊ぶ 泊まる].freeze

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

  # 指定IDのジャンルとその親・子を含めて展開
  # @param ids [Array<Integer>] ジャンルIDの配列
  # @return [Array<Integer>] 展開後のジャンルID配列
  def self.expand_family(ids)
    valid_ids = Array(ids).map(&:to_i).reject(&:zero?)
    return [] if valid_ids.empty?

    where(id: valid_ids).flat_map do |genre|
      [genre.id, genre.parent_id] + where(parent_id: genre.id).pluck(:id)
    end.compact.uniq
  end

  # 検索フィルタ用: カテゴリ別にグループ化されたジャンル構造を返す
  # 戻り値: { "食べる" => [{ genre: グルメ, children: [ラーメン, 寿司, ...] }, ...], ... }
  def self.grouped_by_category
    all_genres = includes(:children).ordered.to_a
    visible_root_genres = all_genres.select { |g| g.visible && g.parent_id.nil? }
    grouped = visible_root_genres.group_by(&:category)

    # CATEGORY_ORDER順で並び替え
    CATEGORY_ORDER.each_with_object({}) do |cat, hash|
      next unless grouped[cat]
      hash[cat] = grouped[cat].map do |genre|
        {
          genre: genre,
          children: genre.children.select(&:visible).sort_by(&:position)
        }
      end
    end
  end

end
