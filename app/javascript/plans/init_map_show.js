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
import { setupSearchBox } from "map/search_box"
import { setupPoiClick } from "map/poi_click"
import { getPlanDataFromPage } from "plans/plan_data"
import { renderRoutePolylinesForShow, fitMapToSpots } from "plans/route_renderer_show"
import { waitForGoogleMaps, isShowPage } from "map/utils"
import { COLORS } from "map/constants"

document.addEventListener("turbo:load", async () => {
  const mapElement = document.getElementById("map")
  if (!mapElement) return
  if (!isShowPage()) return

  // Google Maps APIの準備を待つ
  const isGoogleMapsReady = await waitForGoogleMaps()
  if (!isGoogleMapsReady) {
    console.error("[init_map_show] Google Maps API が利用できません")
    return
  }

  const fallbackCenter = { lat: 35.681236, lng: 139.767125 } // 東京駅

  // 地図生成
  renderMap(fallbackCenter)

  // 検索ボックス
  setupSearchBox()

  // POIクリック（閲覧モード、ボタン表示はmap_modeで制御）
  setupPoiClick(true)

  // プランデータがあればマーカーを描画
  const planData = getPlanDataFromPage()
  if (!planData) return

  const { renderPlanMarkers } = await import("plans/render_plan_markers")
  renderPlanMarkers(planData, { pinColor: COLORS.COMMUNITY })

  // スポット間の経路線を描画
  renderRoutePolylinesForShow()

  // プランのスポット全体が表示されるように地図をフィット
  fitMapToSpots(planData)
})
