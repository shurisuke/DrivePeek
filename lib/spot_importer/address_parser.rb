# frozen_string_literal: true

module SpotImporter
  # 住所文字列から都道府県・市区町村を抽出
  #
  # 使い方:
  #   result = SpotImporter::AddressParser.parse("東京都渋谷区道玄坂1-2-3")
  #   # => { prefecture: "東京都", city: "渋谷区", town: "道玄坂" }
  #
  class AddressParser
    # 都道府県パターン（北海道、東京都、大阪府、京都府、その他県）
    PREFECTURE_PATTERN = /\A(.{2,3}[都道府県])/u

    # 市区町村パターン（政令指定都市の区、市、町、村、特別区）
    CITY_PATTERN = /[都道府県](.+?[市区町村])/u

    # 町名パターン（市区町村の後ろ）
    TOWN_PATTERN = /[市区町村](.+?)[0-9０-９丁目番地号\-−ー]/u

    class << self
      # 住所を解析して prefecture, city, town を抽出
      # @param address [String] 住所文字列
      # @return [Hash] { prefecture:, city:, town: }
      def parse(address)
        return {} if address.blank?

        {
          prefecture: extract_prefecture(address),
          city: extract_city(address),
          town: extract_town(address)
        }.compact
      end

      private

      def extract_prefecture(address)
        match = address.match(PREFECTURE_PATTERN)
        match&.[](1)
      end

      def extract_city(address)
        match = address.match(CITY_PATTERN)
        match&.[](1)
      end

      def extract_town(address)
        match = address.match(TOWN_PATTERN)
        town = match&.[](1)
        # 数字で始まる場合は町名なし
        return nil if town&.match?(/\A[0-9０-９]/)
        town
      end
    end
  end
end
