// app/javascript/plans/planbar_updater.js
//
// ================================================================
// Planbar Updater（単一責務）
// 用途: planbar を Turbo Stream で差し替えて、通知イベントを投げるだけ。
// ================================================================

import { getPlanDataFromPage } from "map/plan_data"

let bound = false

const getPlanId = () => {
  // ✅ 最優先：#map の dataset（ここが一番安定）
  const planIdFromMap = document.getElementById("map")?.dataset?.planId
  if (planIdFromMap) return planIdFromMap

  // 次点：window.planData
  const planData = getPlanDataFromPage()
  return planData?.plan_id || planData?.id || null
}

const refreshPlanbar = async (planId) => {
  const res = await fetch(`/plans/${planId}/planbar`, {
    headers: { Accept: "text/vnd.turbo-stream.html" },
    credentials: "same-origin",
  })
  if (!res.ok) {
    console.warn("[planbar_updater] refreshPlanbar failed", { planId, status: res.status })
    return
  }

  const html = await res.text()

  if (!window.Turbo) {
    console.error("[planbar_updater] Turbo is not available on window")
    return
  }

  window.Turbo.renderStreamMessage(html)

  console.log("[planbar_updater] planbar refreshed", { planId })

  // ✅ 差し替え完了を通知（マーカー更新などは購読側が担当）
  document.dispatchEvent(new CustomEvent("planbar:updated"))
  document.dispatchEvent(new CustomEvent("map:route-updated"))
}

export const bindPlanbarRefresh = () => {
  if (bound) return
  bound = true

  console.log("[planbar_updater] bindPlanbarRefresh")

  document.addEventListener("plan:spot-added", async () => {
    const planId = getPlanId()
    console.log("[planbar_updater] caught plan:spot-added", { planId })
    if (!planId) return
    await refreshPlanbar(planId)
  })

  // ✅ 並び替え完了後も planbar を再描画（position番号の更新）
  document.addEventListener("plan:spots-reordered", async () => {
    const planId = getPlanId()
    console.log("[planbar_updater] caught plan:spots-reordered", { planId })
    if (!planId) return
    await refreshPlanbar(planId)
  })
}