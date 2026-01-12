// app/javascript/plans/toll_used_handler.js
//
// ================================================================
// Toll Used Handler（単一責務）
// 用途: 「有料道路スイッチ」を変更したらRailsへ保存
//   - plan_spots: [data-toll-used-switch="1"]
//   - start_point: [data-start-point-toll-used-switch="1"]
// ================================================================

import { patchTurboStream } from "services/api_client"

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
      await patchTurboStream(`/api/plans/${planId}/start_point`, {
        start_point: { toll_used: tollUsed },
      })
      document.dispatchEvent(new CustomEvent("map:route-updated"))
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
      await patchTurboStream(`/api/plans/${planId}/plan_spots/${planSpotId}/toll_used`, {
        toll_used: tollUsed,
      })
      document.dispatchEvent(new CustomEvent("map:route-updated"))
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
