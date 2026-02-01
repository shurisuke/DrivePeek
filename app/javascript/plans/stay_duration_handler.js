// app/javascript/plans/stay_duration_handler.js
//
// ================================================================
// Stay Duration Handler（単一責務）
// 用途: 「滞在時間 select」を変更したらRailsへ保存し、イベントを投げる。
//  - plan_spots: [data-stay-duration-input="1"]
// PATCH /plans/:plan_id/plan_spots/:id/update_stay_duration
// ================================================================

import { patchTurboStream } from "services/api_client"

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
    await patchTurboStream(
      `/api/plan_spots/${planSpotId}`,
      { stay_duration: stayDuration }
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