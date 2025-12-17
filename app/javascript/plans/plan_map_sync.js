// app/javascript/plans/plan_map_sync.js
//
// ================================================================
// Plan Map Sync（単一責務）
// 用途: プラン画面で発生するイベントを購読し、
//       必要な marker 更新を行う。
// ================================================================

import { getPlanDataFromPage } from "map/plan_data"

let bound = false
let cachedPlanData = null

const setGoalVisible = (visible) => {
  const mapEl = document.getElementById("map")
  if (!mapEl) return
  mapEl.dataset.goalPointVisible = visible ? "true" : "false"
}

const mergeGoalPoint = (planData, goal) => {
  if (!planData || !goal) return planData

  const normalized = {
    address: goal.address,
    lat: Number(goal.lat),
    lng: Number(goal.lng),
  }

  // planDataの揺れを吸収（end_point / goal_point 両方）
  return {
    ...planData,
    goal_point: { ...(planData.goal_point || {}), ...normalized },
    end_point: { ...(planData.end_point || {}), ...normalized },
  }
}

const renderAllMarkersSafe = async (planData) => {
  try {
    const { renderPlanMarkers } = await import("plans/render_plan_markers")
    renderPlanMarkers(planData)
  } catch (e) {
    console.warn("[plan_map_sync] renderPlanMarkers failed", e)
  }
}

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

  cachedPlanData = getPlanDataFromPage()

  // ✅ Turbo遷移後もキャッシュを最新化（bound=trueで再バインドされないため）
  document.addEventListener("turbo:load", () => {
    const fresh = getPlanDataFromPage()
    if (fresh) {
      cachedPlanData = fresh
      console.log("[plan_map_sync] turbo:load - cachedPlanData updated")
    }
  })

  // planbar 差し替え後：planDataを取り直して「全部のピン」を差し直す
  document.addEventListener("planbar:updated", async () => {
    console.log("[plan_map_sync] caught planbar:updated")

    const planData = getPlanDataFromPage()
    if (!planData) return

    cachedPlanData = planData
    await renderAllMarkersSafe(planData)
  })

  // トグルON/OFF：帰宅ピンだけ更新
  document.addEventListener("plan:goal-point-visibility-changed", async (e) => {
    console.log("[plan_map_sync] caught plan:goal-point-visibility-changed", e?.detail)

    const planData = getPlanDataFromPage()
    if (!planData) return

    cachedPlanData = planData
    await refreshGoalMarkerSafe(planData)
  })

  // 帰宅地点の更新：必ず visible=true にして、帰宅ピンを更新
  document.addEventListener("plan:goal-point-updated", async (e) => {
    console.log("[plan_map_sync] caught plan:goal-point-updated", e?.detail)

    // ✅ visible は文字列 "true" を直接セット（boolean禁止）
    const mapEl = document.getElementById("map")
    if (mapEl) {
      mapEl.dataset.goalPointVisible = "true"
      console.log("[plan_map_sync] goalPointVisible set to 'true'")
    } else {
      console.warn("[plan_map_sync] #map not found, cannot set goalPointVisible")
    }

    // ✅ 最新の planData を取得しつつ、null なら cachedPlanData でフォールバック
    const freshPlanData = getPlanDataFromPage()
    console.log("[plan_map_sync] freshPlanData:", freshPlanData ? "found" : "null")
    console.log("[plan_map_sync] cachedPlanData:", cachedPlanData ? "found" : "null")

    const basePlanData = freshPlanData || cachedPlanData
    cachedPlanData = mergeGoalPoint(basePlanData, e?.detail)

    console.log("[plan_map_sync] after merge, cachedPlanData:", {
      hasEndPoint: !!cachedPlanData?.end_point,
      endPoint: cachedPlanData?.end_point,
    })

    if (!cachedPlanData) {
      console.warn("[plan_map_sync] planData is null, cannot refresh goal marker")
      return
    }

    await refreshGoalMarkerSafe(cachedPlanData)
  })

  // 受信確認用（残してOK）
  document.addEventListener("plan:spot-added", (e) => {
    console.log("[plan_map_sync] caught plan:spot-added", e?.detail)
  })
}