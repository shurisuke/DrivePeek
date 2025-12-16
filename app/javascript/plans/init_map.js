// ================================================================
// プラン作成/編集画面: 地図初期化の入口（orchestrator）
// 用途: turbo:load で map 初期化 → 現在地 → plan markers を描画する
// ================================================================

import { renderMap } from "map/render_map";
import { addCurrentLocationMarker } from "map/current_location";
import { getPlanDataFromPage } from "map/plan_data";
import { bindSpotAddHandler } from "plans/spot_add_handler";
import { bindPlanbarRefresh } from "plans/planbar_updater"
import { bindSpotReorderHandler } from "plans/spot_reorder_handler"

// moduleロード時に1回だけバインド（turbo遷移でもOK）
bindSpotAddHandler();
bindPlanbarRefresh()
bindSpotReorderHandler()

document.addEventListener("turbo:load", async () => {
  const mapElement = document.getElementById("map")
  if (!mapElement) return

  const fallbackCenter = { lat: 35.681236, lng: 139.767125 }
  renderMap(fallbackCenter)
  addCurrentLocationMarker()

  const planData = getPlanDataFromPage()
  if (!planData) return

  const { renderPlanMarkers } = await import("plans/render_plan_markers")
  renderPlanMarkers(planData)
})