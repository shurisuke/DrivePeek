// app/javascript/plans/toll_used_handler.js
//
// ================================================================
// Toll Used Handler（単一責務）
// 用途: spot-block内の「有料道路スイッチ」を変更したらRailsへ保存し、
//       planbar再描画のためのイベントを投げる。
// ================================================================

const getCsrfToken = () => {
  const meta = document.querySelector('meta[name="csrf-token"]')
  return meta?.getAttribute("content") || ""
}

const patchTollUsed = async ({ planId, planSpotId, tollUsed }) => {
  const res = await fetch(`/plans/${planId}/plan_spots/${planSpotId}/update_toll_used`, {
    method: "PATCH",
    headers: {
      "Content-Type": "application/json",
      "X-CSRF-Token": getCsrfToken(),
      Accept: "application/json",
    },
    credentials: "same-origin",
    body: JSON.stringify({ toll_used: tollUsed }),
  })

  if (!res.ok) {
    const err = await res.json().catch(() => ({}))
    throw new Error(err.message || "有料道路の更新に失敗しました")
  }

  return res.json()
}

const handleChange = async (e) => {
  const el = e.target
  if (!(el instanceof HTMLInputElement)) return
  if (!el.matches('[data-toll-used-switch="1"]')) return
  console.log("[toll_used_handler] switch changed", el.dataset, el.checked)

  const planId = el.dataset.planId
  const planSpotId = el.dataset.planSpotId
  if (!planId || !planSpotId) return

  const tollUsed = el.checked

  try {
    const json = await patchTollUsed({ planId, planSpotId, tollUsed })

    document.dispatchEvent(
      new CustomEvent("plan:plan-spot-toll-used-updated", {
        detail: { plan_id: Number(planId), plan_spot_id: Number(planSpotId), toll_used: json.toll_used },
      })
    )
  } catch (err) {
    alert(err.message)
    // 失敗時は元に戻す（UIとDB不一致防止）
    el.checked = !tollUsed
  }
}

let bound = false

export const bindTollUsedHandler = () => {
  if (bound) return
  bound = true

  document.addEventListener("change", handleChange)
}