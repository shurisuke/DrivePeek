// app/javascript/map/init_map.js
//
// ================================================================
// Map Initializer（単一責務）
// 用途: 地図があるページで map を初期化し、初回の marker 描画を行う。
//       プラン固有のイベント購読は plans/plan_map_sync に委譲する。
// ================================================================

import { renderMap } from "map/render_map"
import { addCurrentLocationMarker } from "map/current_location"
import { getPlanDataFromPage } from "map/plan_data"
import { bindSpotAddHandler } from "plans/spot_add_handler"
import { bindPlanbarRefresh } from "plans/planbar_updater"
import { bindPlanMapSync } from "plans/plan_map_sync"
import { bindSpotReorderHandler } from "plans/spot_reorder_handler"
import { bindTollUsedHandler } from "plans/toll_used_handler"

console.log("[init_map] module loaded")

// プラン画面で必要な "購読" はここで一括バインド（複数回呼んでも内部でガード）
bindSpotAddHandler()
bindPlanbarRefresh()
bindPlanMapSync()
bindSpotReorderHandler()
bindTollUsedHandler()

document.addEventListener("turbo:load", async () => {
  console.log("[init_map] turbo:load fired")

  const mapElement = document.getElementById("map")
  if (!mapElement) {
    console.log("[init_map] #map not found. skip.")
    return
  }

  // 初期値はOFF（トグル操作でONになったら goal_point_visibility_controller が更新）
  if (!mapElement.dataset.goalPointVisible) {
    mapElement.dataset.goalPointVisible = "false"
  }
  console.log("[init_map] #map.dataset.goalPointVisible =", mapElement.dataset.goalPointVisible)

  const fallbackCenter = { lat: 35.681236, lng: 139.767125 } // 東京駅
  console.log("[init_map] renderMap()", fallbackCenter)

  renderMap(fallbackCenter)
  addCurrentLocationMarker()

  const planData = getPlanDataFromPage()

  // ✅ プランデータが無い画面（例: スポット詳細など）でも map は動く
  if (!planData) {
    console.log("[init_map] planData not found. renderPlanMarkers skipped.")
    return
  }

  console.log("[init_map] planData found. renderPlanMarkers()")
  const { renderPlanMarkers } = await import("plans/render_plan_markers")
  renderPlanMarkers(planData)
})