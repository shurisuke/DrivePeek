// ================================================================
// 地図生成（単一責務）
// 用途: Google Map を生成して state に登録する
//       検索・POIクリックは別モジュールで設定
// ================================================================

import { setMapInstance } from "map/state"

/**
 * 地図を初期化する
 * @param {Object} center - 中心座標 { lat, lng }
 */
export const renderMap = (center) => {
  const mapElement = document.getElementById("map")
  if (!mapElement) {
    console.error("地図を表示する #map 要素が見つかりません")
    return
  }

  console.log("🗺️ 地図を初期化します（中心座標）:", center)

  const map = new google.maps.Map(mapElement, {
    center,
    zoom: 12,
    disableDefaultUI: true,
    keyboardShortcuts: false,
  })

  setMapInstance(map)
}
