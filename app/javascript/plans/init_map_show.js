// app/javascript/plans/init_map_show.js
//
// ================================================================
// Map Initializer - 詳細画面用（単一責務）
// 用途: プラン詳細画面で map を初期化（閲覧専用）
//       - 地図生成
//       - POIクリック（閲覧モード、追加ボタンなし）
//       - マーカー描画
//       - 経路線描画
//       - プランのスポット全体にフィット
// ================================================================

import { renderMap } from "map/render_map"
import { setupPoiClickForView } from "map/poi_click"
import { getPlanDataFromPage } from "plans/plan_data"
import { renderRoutePolylinesForShow, fitMapToSpots } from "plans/route_renderer_show"
import { waitForGoogleMaps, isShowPage } from "map/utils"
import { COLORS } from "map/constants"

console.log("[init_map_show] module loaded")

document.addEventListener("turbo:load", async () => {
  console.log("[init_map_show] turbo:load fired")

  const mapElement = document.getElementById("map")
  if (!mapElement) {
    console.log("[init_map_show] #map not found. skip.")
    return
  }

  // 詳細画面でない場合はスキップ
  if (!isShowPage()) {
    console.log("[init_map_show] not show page. skip.")
    return
  }

  // Google Maps APIの準備を待つ
  const isGoogleMapsReady = await waitForGoogleMaps()
  if (!isGoogleMapsReady) {
    console.error("[init_map_show] Google Maps API が利用できません")
    return
  }

  const fallbackCenter = { lat: 35.681236, lng: 139.767125 } // 東京駅
  console.log("[init_map_show] initializing map...")

  // 地図生成
  renderMap(fallbackCenter)

  // POIクリック（閲覧モード、追加ボタンなし）
  setupPoiClickForView()

  // プランデータがあればマーカーを描画
  const planData = getPlanDataFromPage()
  if (!planData) {
    console.log("[init_map_show] planData not found. renderPlanMarkers skipped.")
    return
  }

  console.log("[init_map_show] planData found. renderPlanMarkers()")
  const { renderPlanMarkers } = await import("plans/render_plan_markers")
  renderPlanMarkers(planData, { pinColor: COLORS.COMMUNITY })

  // スポット間の経路線を描画
  renderRoutePolylinesForShow()

  // プランのスポット全体が表示されるように地図をフィット
  fitMapToSpots(planData)
})
