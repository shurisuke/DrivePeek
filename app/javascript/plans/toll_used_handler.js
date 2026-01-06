// app/javascript/plans/toll_used_handler.js
//
// ================================================================
// Toll Used Handler（単一責務）
// 用途: 「有料道路スイッチ」を変更したらRailsへ保存し、必要ならイベントを投げる。
//   - plan_spots: [data-toll-used-switch="1"]
//   - start_point: [data-start-point-toll-used-switch="1"]
// ================================================================

import { patch } from "services/api_client"

// ------------------------------
// plan_spots
// PATCH /plans/:plan_id/plan_spots/:id/update_toll_used
// ------------------------------
const patchPlanSpotTollUsed = async ({ planId, planSpotId, tollUsed }) => {
  return patch(
    `/plans/${planId}/plan_spots/${planSpotId}/update_toll_used`,
    { toll_used: tollUsed }
  )
}

// ------------------------------
// start_point
// PATCH /plans/:plan_id/start_point
// ------------------------------
const patchStartPointTollUsed = async ({ planId, tollUsed }) => {
  return patch(
    `/plans/${planId}/start_point`,
    { start_point: { toll_used: tollUsed } }
  )
}

// ------------------------------
// イベント委譲ハンドラ
// ------------------------------
const handleChange = async (e) => {
  const el = e.target
  if (!(el instanceof HTMLInputElement)) return

  // --- start_point のトグル ---
  if (el.matches('[data-start-point-toll-used-switch="1"]')) {
    const planId = el.dataset.planId
    if (!planId) return

    const tollUsed = el.checked

    try {
      const json = await patchStartPointTollUsed({ planId, tollUsed })

      document.dispatchEvent(
        new CustomEvent("plan:start-point-toll-used-updated", {
          detail: {
            plan_id: Number(planId),
            toll_used: json.start_point?.toll_used,
          },
        })
      )
    } catch (err) {
      alert(err.message)
      el.checked = !tollUsed // 元に戻す
    }
    return
  }

  // --- plan_spots のトグル ---
  if (el.matches('[data-toll-used-switch="1"]')) {
    const planId = el.dataset.planId
    const planSpotId = el.dataset.planSpotId
    if (!planId || !planSpotId) return

    const tollUsed = el.checked

    try {
      const json = await patchPlanSpotTollUsed({ planId, planSpotId, tollUsed })

      document.dispatchEvent(
        new CustomEvent("plan:plan-spot-toll-used-updated", {
          detail: {
            plan_id: Number(planId),
            plan_spot_id: Number(planSpotId),
            toll_used: json.toll_used,
          },
        })
      )
    } catch (err) {
      alert(err.message)
      el.checked = !tollUsed // 元に戻す
    }
  }
}

// ------------------------------
// バインド（二重登録防止）
// ------------------------------
let bound = false

export const bindTollUsedHandler = () => {
  if (bound) return
  bound = true
  document.addEventListener("change", handleChange)
}
