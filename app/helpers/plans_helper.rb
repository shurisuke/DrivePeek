module PlansHelper
  # 距離をフォーマットして表示
  # - 10km以上（整数部2桁以上）: 整数部のみ表示
  # - 10km未満: 小数点以下1桁まで表示
  def format_distance(distance)
    return nil if distance.blank?

    value = distance.to_f
    if value >= 10
      value.to_i.to_s
    else
      number_with_precision(value, precision: 1, strip_insignificant_zeros: true)
    end
  end

  # スポット配列からタグ名を重複なしで収集
  # spots: [{ name:, address:, tags: ["tag1", "tag2"] }, ...]
  def collect_unique_tags(spots)
    return [] if spots.blank?

    spots.flat_map { |spot| spot[:tags] || [] }.uniq
  end
end
