// app/javascript/plans/init_map_edit.js
//
// ================================================================
// Map Initializer - 編集画面用
// 用途: プラン編集画面で map を初期化し、全機能を有効化
//       - 地図生成
//       - 検索ボックス
//       - POIクリック（追加ボタンあり）
//       - 各種ハンドラー
// ================================================================

import { renderMap } from "map/render_map"
import { setupSearchBox } from "map/search_box"
import { setupPoiClickForEdit } from "map/poi_click"
import { addCurrentLocationMarker } from "map/current_location"
import { getPlanDataFromPage } from "plans/plan_data"
import { bindSpotAddHandler } from "plans/spot_add_handler"
import { bindPlanbarRefresh } from "planbar/updater"
import { bindPlanMapSync } from "plans/plan_map_sync"
import { bindSpotReorderHandler } from "plans/spot_reorder_handler"
import { bindTollUsedHandler } from "plans/toll_used_handler"
import { bindStayDurationHandler } from "plans/stay_duration_handler"

console.log("[init_map_edit] module loaded")

// プラン編集画面で必要な "購読" はここで一括バインド（複数回呼んでも内部でガード）
bindSpotAddHandler()
bindPlanbarRefresh()
bindPlanMapSync()
bindSpotReorderHandler()
bindTollUsedHandler()
bindStayDurationHandler()

/**
 * Google Maps APIが利用可能になるまで待機する
 */
const waitForGoogleMaps = (maxWait = 5000, interval = 100) => {
  return new Promise((resolve) => {
    if (typeof google !== "undefined" && google.maps) {
      resolve(true)
      return
    }

    const startTime = Date.now()
    const checkInterval = setInterval(() => {
      if (typeof google !== "undefined" && google.maps) {
        clearInterval(checkInterval)
        resolve(true)
      } else if (Date.now() - startTime > maxWait) {
        clearInterval(checkInterval)
        console.error("[init_map_edit] Google Maps API の読み込みがタイムアウトしました")
        resolve(false)
      }
    }, interval)
  })
}

/**
 * 編集画面かどうかを判定
 */
const isEditPage = () => {
  const mapElement = document.getElementById("map")
  return mapElement && mapElement.dataset.mapMode === "edit"
}

document.addEventListener("turbo:load", async () => {
  console.log("[init_map_edit] turbo:load fired")

  const mapElement = document.getElementById("map")
  if (!mapElement) {
    console.log("[init_map_edit] #map not found. skip.")
    return
  }

  // 編集画面でない場合はスキップ
  if (!isEditPage()) {
    console.log("[init_map_edit] not edit page. skip.")
    return
  }

  // Google Maps APIの準備を待つ
  const isGoogleMapsReady = await waitForGoogleMaps()
  if (!isGoogleMapsReady) {
    console.error("[init_map_edit] Google Maps API が利用できません")
    return
  }

  if (!mapElement.dataset.goalPointVisible) {
    mapElement.dataset.goalPointVisible = "false"
  }
  console.log("[init_map_edit] #map.dataset.goalPointVisible =", mapElement.dataset.goalPointVisible)

  const fallbackCenter = { lat: 35.681236, lng: 139.767125 } // 東京駅
  console.log("[init_map_edit] initializing map...")

  // 地図生成
  renderMap(fallbackCenter)

  // 検索ボックスを有効化
  setupSearchBox()

  // POIクリック（追加ボタンあり）を有効化
  setupPoiClickForEdit()

  // 現在地マーカー
  addCurrentLocationMarker()

  // プランデータがあればマーカーを描画
  const planData = getPlanDataFromPage()
  if (!planData) {
    console.log("[init_map_edit] planData not found. renderPlanMarkers skipped.")
    return
  }

  console.log("[init_map_edit] planData found. renderPlanMarkers()")
  const { renderPlanMarkers } = await import("plans/render_plan_markers")
  renderPlanMarkers(planData)
})
