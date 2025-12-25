# frozen_string_literal: true

# Google Place Types の I18n 辞書を逆引きするモジュール
# 日本語タグ名から英語キーを取得する（検索用）
module GooglePlaceTypesDictionary
  class << self
    # 日本語の表示名から対応する英語キーの配列を返す
    # 完全一致のみ対象（部分一致は行わない）
    # 該当なしの場合は空配列を返す
    def keys_for(query)
      return [] if query.blank?

      reverse_dictionary[query.to_s.strip] || []
    end

    private

    # 日本語 => [英語キー, ...] の逆引き辞書をメモ化
    def reverse_dictionary
      @reverse_dictionary ||= build_reverse_dictionary
    end

    # I18n辞書から逆引き用ハッシュを構築
    # 同じ日本語表記に複数の英語キーが対応する場合は配列にまとめる
    def build_reverse_dictionary
      result = Hash.new { |h, k| h[k] = [] }

      translations = fetch_translations
      return result if translations.blank?

      translations.each do |english_key, japanese_value|
        next if japanese_value.blank?

        result[japanese_value.to_s] << english_key.to_s
      end

      result
    end

    # I18n辞書から google_place_types を取得
    def fetch_translations
      I18n.t("google_place_types", locale: :ja, default: {})
    rescue StandardError
      {}
    end
  end
end
