# frozen_string_literal: true

module SpotImporter
  # 関東圏の10kmグリッド座標を生成
  #
  # 使い方:
  #   grids = SpotImporter::GridGenerator.kanto_grids
  #   # => [{ lat: 35.5, lng: 139.5 }, ...]
  #
  class GridGenerator
    # 緯度1度 ≈ 111km
    LAT_PER_KM = 1.0 / 111.0

    # 経度1度 ≈ 91km（日本の緯度で概算）
    LNG_PER_KM = 1.0 / 91.0

    # 関東圏の範囲（1都6県をカバー）
    KANTO_BOUNDS = {
      north: 37.0,   # 栃木県北端
      south: 34.9,   # 神奈川県南端
      east: 140.9,   # 千葉県東端
      west: 138.4    # 群馬県西端
    }.freeze

    class << self
      # 関東圏の10kmグリッド座標を生成
      # @param grid_size_km [Float] グリッドサイズ（km）
      # @return [Array<Hash>] [{ lat:, lng: }, ...]
      def kanto_grids(grid_size_km: 10.0)
        generate_grids(KANTO_BOUNDS, grid_size_km)
      end

      # テスト用: 東京駅周辺の1グリッドのみ
      # @return [Array<Hash>]
      def test_grids
        [{ lat: 35.6812, lng: 139.7671 }]
      end

      private

      def generate_grids(bounds, grid_size_km)
        lat_step = grid_size_km * LAT_PER_KM
        lng_step = grid_size_km * LNG_PER_KM

        grids = []
        lat = bounds[:south]

        while lat <= bounds[:north]
          lng = bounds[:west]
          while lng <= bounds[:east]
            grids << { lat: lat.round(4), lng: lng.round(4) }
            lng += lng_step
          end
          lat += lat_step
        end

        grids
      end
    end
  end
end
