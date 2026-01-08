// app/javascript/plans/init_map_show.js
//
// ================================================================
// Map Initializer - 詳細画面用
// 用途: プラン詳細画面で map を初期化（閲覧専用）
//       - 地図生成
//       - POIクリック（閲覧モード、追加ボタンなし）
//       - マーカー描画
//       ※ 検索ボックス、各種編集ハンドラーは無効
// ================================================================

import { renderMap } from "map/render_map"
import { setupPoiClickForView } from "map/poi_click"
import { addCurrentLocationMarker } from "map/current_location"
import { getPlanDataFromPage } from "plans/plan_data"

console.log("[init_map_show] module loaded")

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
        console.error("[init_map_show] Google Maps API の読み込みがタイムアウトしました")
        resolve(false)
      }
    }, interval)
  })
}

/**
 * 詳細画面かどうかを判定
 */
const isShowPage = () => {
  const mapElement = document.getElementById("map")
  return mapElement && mapElement.dataset.mapMode === "show"
}

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

  // 現在地マーカー
  addCurrentLocationMarker()

  // プランデータがあればマーカーを描画
  const planData = getPlanDataFromPage()
  if (!planData) {
    console.log("[init_map_show] planData not found. renderPlanMarkers skipped.")
    return
  }

  console.log("[init_map_show] planData found. renderPlanMarkers()")
  const { renderPlanMarkers } = await import("plans/render_plan_markers")
  renderPlanMarkers(planData)
})
