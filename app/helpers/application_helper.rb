module ApplicationHelper
  def remaining_minutes(sent_at, duration: 30.minutes)
    ((sent_at + duration - Time.current) / 60).ceil
  end

  # ================================================================
  # 時刻・日付フォーマット
  # ================================================================

  # 時刻表示（nil時は "--:--" を返す）
  def format_time_or_blank(time)
    time&.strftime("%H:%M") || "--:--"
  end

  # 日時フォーマット: "2024/01/15 12:30"
  def format_datetime(time)
    time&.strftime("%Y/%m/%d %H:%M")
  end

  # 短い日付フォーマット: "1/15"
  def format_date_short(date)
    date&.strftime("%-m/%-d")
  end

  # ================================================================
  # 場所表示
  # ================================================================

  # 都道府県/市区町村 を結合して表示
  # - Hash または オブジェクト を受け付ける
  def format_spot_location(spot)
    prefecture = spot.is_a?(Hash) ? spot[:prefecture] : spot.prefecture
    city = spot.is_a?(Hash) ? spot[:city] : spot.city

    [ prefecture, city ].compact.reject(&:blank?).join("/")
  end

  # ユーザーIDからアバター色を生成（50色）
  AVATAR_COLORS = %w[
    #FF6B6B #FF8E72 #FFA07A #FFB347 #FFCC5C
    #FFD93D #F7DC6F #FFEAA7 #D4E157 #AED581
    #81C784 #66BB6A #4CAF50 #26A69A #009688
    #4ECDC4 #00BCD4 #00ACC1 #0097A7 #00838F
    #45B7D1 #4FC3F7 #29B6F6 #03A9F4 #039BE5
    #85C1E9 #64B5F6 #42A5F5 #5C6BC0 #7E57C2
    #9575CD #BB8FCE #AB47BC #BA68C8 #CE93D8
    #DDA0DD #F48FB1 #F06292 #EC407A #E91E63
    #FF7F50 #FF6F61 #EF5350 #E57373 #F44336
    #D32F2F #C62828 #8D6E63 #A1887F #78909C
  ].freeze

  def avatar_color_for(user)
    AVATAR_COLORS[user.id % AVATAR_COLORS.length]
  end
end
