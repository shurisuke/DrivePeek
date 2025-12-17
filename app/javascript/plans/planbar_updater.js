// app/javascript/plans/planbar_updater.js
//
// ================================================================
// Planbar Updater（単一責務）
// 用途: planbar を Turbo Stream で差し替えて、通知イベントを投げるだけ。
// ================================================================

import { getPlanDataFromPage } from "map/plan_data"

const refreshPlanbar = async (planId) => {
  const res = await fetch(`/plans/${planId}/planbar`, {
    headers: { Accept: "text/vnd.turbo-stream.html" },
    credentials: "same-origin",
  })
  if (!res.ok) return

  const html = await res.text()
  Turbo.renderStreamMessage(html)

  console.log("[planbar_updater] planbar refreshed", { planId })

  // ✅ 差し替え完了を通知（マーカー更新などは購読側が担当）
  document.dispatchEvent(new CustomEvent("planbar:updated"))
  document.dispatchEvent(new CustomEvent("map:route-updated"))
}

export const bindPlanbarRefresh = () => {
  document.addEventListener("plan:spot-added", async () => {
    const planData = getPlanDataFromPage()
    const planId = planData?.plan_id || planData?.id
    if (!planId) return

    await refreshPlanbar(planId)
  })
}