// app/javascript/plans/stay_duration_handler.js
//
// ================================================================
// Stay Duration Handler（単一責務）
// 用途: 「滞在時間 select」を変更したらRailsへ保存し、イベントを投げる。
//  - plan_spots: [data-stay-duration-input="1"]
// PATCH /plans/:plan_id/plan_spots/:id/update_stay_duration
// ================================================================

import { patch } from "services/api_client"

const patchStayDuration = async ({ planId, planSpotId, stayDuration }) => {
  return patch(
    `/plans/${planId}/plan_spots/${planSpotId}/update_stay_duration`,
    { stay_duration: stayDuration }
  )
}

const handleChange = async (e) => {
  const el = e.target
  if (!(el instanceof HTMLSelectElement)) return
  if (!el.matches('[data-stay-duration-input="1"]')) return

  const planId = el.dataset.planId
  const planSpotId = el.dataset.planSpotId
  if (!planId || !planSpotId) return

  const before = el.dataset.beforeValue ?? ""
  const value = el.value // "" の場合は未設定扱い
  const stayDuration = value === "" ? "" : Number(value)

  try {
    const json = await patchStayDuration({ planId, planSpotId, stayDuration })

    el.dataset.beforeValue = value

    document.dispatchEvent(
      new CustomEvent("plan:plan-spot-stay-duration-updated", {
        detail: {
          plan_id: Number(planId),
          plan_spot_id: Number(planSpotId),
          stay_duration: json.stay_duration,
        },
      })
    )
  } catch (err) {
    alert(err.message)
    el.value = before
  }
}

// ------------------------------
// バインド（二重登録防止）
// ------------------------------
let bound = false

export const bindStayDurationHandler = () => {
  if (bound) return
  bound = true
  document.addEventListener("change", handleChange)
}