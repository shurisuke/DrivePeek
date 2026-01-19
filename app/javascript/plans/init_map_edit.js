// app/javascript/plans/init_map_edit.js
//
// ================================================================
// Map Initializer - 編集画面用
// 用途: プラン編集画面で map を初期化し、全機能を有効化
//       - 地図生成
//       - 検索ボックス
//       - POIクリック（追加ボタンあり）
//       - 編集画面専用ハンドラーのバインド
// ================================================================

import { renderMap } from "map/render_map"
import { setupSearchBox } from "map/search_box"
import { setupPoiClick } from "map/poi_click"
import { addCurrentLocationMarker } from "map/current_location"
import { getPlanDataFromPage } from "plans/plan_data"
import { waitForGoogleMaps, isEditPage } from "map/utils"
import { bindPlanMapSync } from "plans/plan_map_sync"
import { bindSpotReorderHandler } from "plans/spot_reorder_handler"
import { bindTollUsedHandler } from "plans/toll_used_handler"
import { bindStayDurationHandler } from "plans/stay_duration_handler"

// 編集画面専用ハンドラーをバインド（各ハンドラーは内部で二重バインド防止済み）
bindPlanMapSync()
bindSpotReorderHandler()
bindTollUsedHandler()
bindStayDurationHandler()

document.addEventListener("turbo:load", async () => {
  const mapElement = document.getElementById("map")
  if (!mapElement) return
  if (!isEditPage()) return

  // Google Maps APIの準備を待つ
  const isGoogleMapsReady = await waitForGoogleMaps()
  if (!isGoogleMapsReady) {
    console.error("[init_map_edit] Google Maps API が利用できません")
    return
  }

  if (!mapElement.dataset.goalPointVisible) {
    mapElement.dataset.goalPointVisible = "false"
  }

  const fallbackCenter = { lat: 35.681236, lng: 139.767125 } // 東京駅

  // 地図生成
  renderMap(fallbackCenter)

  // 検索ボックスを有効化
  setupSearchBox()

  // POIクリック（追加ボタンあり）を有効化
  setupPoiClick(true)

  // 現在地マーカー
  addCurrentLocationMarker()

  // プランデータがあればマーカーを描画
  const planData = getPlanDataFromPage()
  if (!planData) return

  const { renderPlanMarkers } = await import("plans/render_plan_markers")
  renderPlanMarkers(planData)
})
