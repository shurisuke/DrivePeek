class AddEmojiToGenres < ActiveRecord::Migration[8.1]
  def change
    add_column :genres, :emoji, :string, default: "✨"

    reversible do |dir|
      dir.up do
        # グルメ系（全て🍴）
        update_emoji(%w[gourmet ramen sushi yakiniku curry washoku udon_soba tempura tonkatsu yakitori seafood okonomiyaki gyudon italian french steak hamburger pizza chinese gyoza korean thai indian vietnamese fastfood takoyaki hamburg family_restaurant shabu_shabu nabe teishoku izakaya], "🍴")

        # カフェ系
        update_emoji(%w[cafe cafe_shop kissaten], "☕")
        update_emoji(%w[pancake crepe], "🥞")
        update_emoji(%w[cake_shop], "🍰")
        update_emoji(%w[bakery], "🥐")
        update_emoji(%w[tapioca], "🧋")
        update_emoji(%w[donut], "🍩")
        update_emoji(%w[icecream], "🍦")
        update_emoji(%w[wagashi], "🍡")

        # ショッピング系
        update_emoji(%w[shopping variety_store souvenir_shop], "🛍️")
        update_emoji(%w[convenience_store], "🏪")
        update_emoji(%w[supermarket], "🛒")
        update_emoji(%w[department_store], "🏬")
        update_emoji(%w[outlet], "👗")
        update_emoji(%w[farm_stand], "🥬")
        update_emoji(%w[bookstore library], "📚")
        update_emoji(%w[flower_shop], "💐")
        update_emoji(%w[liquor_store], "🍾")
        update_emoji(%w[home_center], "🔧")
        update_emoji(%w[pet_shop], "🐾")
        update_emoji(%w[car_shop], "🚗")
        update_emoji(%w[furniture_store], "🪑")

        # 観光系
        update_emoji(%w[sightseeing cultural_property historic_site museum_category art_gallery museum science_museum memorial_hall], "🏛️")
        update_emoji(%w[castle], "🏯")
        update_emoji(%w[scenic_view], "🌅")
        update_emoji(%w[night_view], "🌃")
        update_emoji(%w[shrine_temple], "⛩️")

        # 温浴系
        update_emoji(%w[onsen sauna], "♨️")

        # 動物系
        update_emoji(%w[zoo], "🦁")
        update_emoji(%w[aquarium], "🐬")
        update_emoji(%w[dog_run], "🐕")
        update_emoji(%w[ranch], "🐄")
        update_emoji(%w[fishing_pond], "🎣")

        # 自然・アウトドア系
        update_emoji(%w[park garden_flower], "🌳")
        update_emoji(%w[lake_waterfall dam water_park], "💧")
        update_emoji(%w[sea_coast], "🏖️")
        update_emoji(%w[mountain], "⛰️")
        update_emoji(%w[cave], "🕳️")
        update_emoji(%w[campsite], "⛺")

        # レジャー系
        update_emoji(%w[theme_park], "🎢")
        update_emoji(%w[activity], "🪂")
        update_emoji(%w[karaoke], "🎤")
        update_emoji(%w[bowling], "🎳")
        update_emoji(%w[ropeway], "🚡")

        # 宿泊・飲み系
        update_emoji(%w[accommodation], "🏨")
        update_emoji(%w[bar snack_bar winery], "🍷")

        # 交通系
        update_emoji(%w[roadside_station], "🚗")
        update_emoji(%w[station], "🚉")
        update_emoji(%w[airport], "✈️")
        update_emoji(%w[port], "⚓")
        update_emoji(%w[parking], "🅿️")
        update_emoji(%w[gas_station], "⛽")

        # 公共施設系
        update_emoji(%w[hospital], "🏥")
        update_emoji(%w[school], "🏫")
        update_emoji(%w[government_office], "🏢")
        update_emoji(%w[police], "👮")
        update_emoji(%w[fire_station], "🚒")
        update_emoji(%w[post_office], "📮")
        update_emoji(%w[bank], "🏦")

        # 施設系
        update_emoji(%w[factory], "🏭")
      end
    end
  end

  private

  def update_emoji(slugs, emoji)
    execute "UPDATE genres SET emoji = '#{emoji}' WHERE slug IN (#{slugs.map { |s| "'#{s}'" }.join(', ')})"
  end
end
