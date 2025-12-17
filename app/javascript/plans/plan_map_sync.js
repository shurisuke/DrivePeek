// app/javascript/plans/plan_map_sync.js
//
// ================================================================
// Plan Map Sync（単一責務）
// 用途: プラン画面で発生するイベントを購読し、
//       「帰宅マーカーだけ」必要に応じて更新する。
// ================================================================

import { getPlanDataFromPage } from "map/plan_data"

let bound = false
let cachedPlanData = null

const refreshGoalMarkerSafe = async (planData) => {
  try {
    const { refreshGoalMarker } = await import("plans/render_plan_markers")
    refreshGoalMarker(planData)
  } catch (e) {
    console.warn("[plan_map_sync] refreshGoalMarker failed", e)
  }
}

export const bindPlanMapSync = () => {
  if (bound) return
  bound = true

  console.log("[plan_map_sync] bindPlanMapSync")

  // planbar 差し替え後（DOMが変わるので planData を取り直す）
  document.addEventListener("planbar:updated", async () => {
    console.log("[plan_map_sync] caught planbar:updated")

    const planData = getPlanDataFromPage()
    if (!planData) return

    cachedPlanData = planData
    await refreshGoalMarkerSafe(planData)
  })

  // 帰宅地点表示トグルの変更（ON/OFFに追従して帰宅マーカーだけ更新）
  document.addEventListener("plan:goal-point-visibility-changed", async (e) => {
    console.log("[plan_map_sync] caught plan:goal-point-visibility-changed", e?.detail)

    const planData = getPlanDataFromPage()
    if (!planData) return

    cachedPlanData = planData
    await refreshGoalMarkerSafe(planData)
  })

  // 帰宅地点の更新（Enterで変更）→ ピン位置も更新
  document.addEventListener("plan:goal-point-updated", async (e) => {
    console.log("[plan_map_sync] caught plan:goal-point-updated", e?.detail)

    if (cachedPlanData && e?.detail) {
      cachedPlanData.goal_point = { ...(cachedPlanData.goal_point || {}), ...e.detail }
      cachedPlanData.end_point = { ...(cachedPlanData.end_point || {}), ...e.detail }
    }

    const planData = cachedPlanData || getPlanDataFromPage()
    if (!planData) return

    await refreshGoalMarkerSafe(planData)
  })

  // 受信確認用（必要なら残す）
  document.addEventListener("plan:spot-added", (e) => {
    console.log("[plan_map_sync] caught plan:spot-added", e?.detail)
  })
}