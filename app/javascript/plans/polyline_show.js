// app/javascript/plans/polyline_show.js
//
// ================================================================
// Polyline Renderer（詳細画面用）
// 用途: スポット間の経路線を描画（詳細画面専用）
//       ※ 出発地点→最初のスポット、最後のスポット→帰宅地点の経路は
//          プライバシー保護のため描画しない
// ================================================================

import { getMapInstance } from "map/state"
import { ROUTE_POLYLINE_STYLE } from "map/constants"

/**
 * スポット間の経路線を描画する（詳細画面用）
 */
export const renderRoutePolylinesForShow = () => {
  const map = getMapInstance()
  if (!map) return

  // geometry library がロードされているか確認
  if (!google?.maps?.geometry?.encoding?.decodePath) {
    console.warn("[polyline_show] geometry library not loaded")
    return
  }

  // DOM から polyline 情報を収集（position順）
  const spotBlocks = document.querySelectorAll(".spot-block[data-polyline][data-position]")
  const sortedBlocks = Array.from(spotBlocks).sort((a, b) => {
    return Number(a.dataset.position) - Number(b.dataset.position)
  })

  // 各スポットのpolylineは「このスポット→次のスポット(or帰宅地点)」の経路
  // 最後のスポットのpolylineは帰宅地点への経路なのでプライバシー保護のため除外
  const polylinesToRender = sortedBlocks
    .slice(0, -1) // 最後のスポット（→帰宅地点）を除外
    .map((block) => block.dataset.polyline)
    .filter(Boolean)

  if (polylinesToRender.length === 0) return

  polylinesToRender.forEach((encoded) => {
    try {
      const path = google.maps.geometry.encoding.decodePath(encoded)
      new google.maps.Polyline({
        path,
        map,
        ...ROUTE_POLYLINE_STYLE,
      })
    } catch (e) {
      console.warn("[polyline_show] Failed to decode polyline:", e)
    }
  })
}
