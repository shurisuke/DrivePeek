// app/javascript/map/init_map.js
//
// ================================================================
// Map Initializer（単一責務）
// 用途: 地図があるページで map を初期化し、初回の marker 描画を行う。
//       プラン固有のイベント購読は plans/plan_map_sync に委譲する。
// ================================================================

import { renderMap } from "map/render_map"
import { addCurrentLocationMarker } from "map/current_location"
import { getPlanDataFromPage } from "plans/plan_data"
import { bindSpotAddHandler } from "plans/spot_add_handler"
import { bindPlanbarRefresh } from "planbar/updater"
import { bindPlanMapSync } from "plans/plan_map_sync"
import { bindSpotReorderHandler } from "plans/spot_reorder_handler"
import { bindTollUsedHandler } from "plans/toll_used_handler"
import { bindStayDurationHandler } from "plans/stay_duration_handler"

console.log("[init_map] module loaded")

// プラン画面で必要な "購読" はここで一括バインド（複数回呼んでも内部でガード）
bindSpotAddHandler()
bindPlanbarRefresh()
bindPlanMapSync()
bindSpotReorderHandler()
bindTollUsedHandler()
bindStayDurationHandler()

/**
 * Google Maps APIが利用可能になるまで待機する
 * @param {number} maxWait - 最大待機時間（ミリ秒）
 * @param {number} interval - チェック間隔（ミリ秒）
 * @returns {Promise<boolean>} - APIが利用可能になったらtrue
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
        console.error("[init_map] Google Maps API の読み込みがタイムアウトしました")
        resolve(false)
      }
    }, interval)
  })
}

document.addEventListener("turbo:load", async () => {
  console.log("[init_map] turbo:load fired")

  const mapElement = document.getElementById("map")
  if (!mapElement) {
    console.log("[init_map] #map not found. skip.")
    return
  }

  // Google Maps APIの準備を待つ
  const isGoogleMapsReady = await waitForGoogleMaps()
  if (!isGoogleMapsReady) {
    console.error("[init_map] Google Maps API が利用できません")
    return
  }

  if (!mapElement.dataset.goalPointVisible) {
    mapElement.dataset.goalPointVisible = "false"
  }
  console.log("[init_map] #map.dataset.goalPointVisible =", mapElement.dataset.goalPointVisible)

  const fallbackCenter = { lat: 35.681236, lng: 139.767125 } // 東京駅
  console.log("[init_map] renderMap()", fallbackCenter)

  renderMap(fallbackCenter)
  addCurrentLocationMarker()

  const planData = getPlanDataFromPage()
  if (!planData) {
    console.log("[init_map] planData not found. renderPlanMarkers skipped.")
    return
  }

  console.log("[init_map] planData found. renderPlanMarkers()")
  const { renderPlanMarkers } = await import("plans/render_plan_markers")
  renderPlanMarkers(planData)
})