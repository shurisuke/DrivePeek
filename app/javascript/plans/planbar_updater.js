// app/javascript/plans/planbar_updater.js
//
// ================================================================
// Planbar Updater（単一責務）
// 用途: planbar を Turbo Stream で差し替えて、通知イベントを投げるだけ。
// 追加: planbar差し替え前後で「開いていたスポット詳細(collapse)」を復元する
// 追加: planbar差し替え前後で「スクロール位置(planbar__content)」も復元する
// 追加: Turbo復元時はcollapseのアニメーションを無効化する
//
// ✅ 重要：init_map 側が named import しているので
//         bindPlanbarRefresh を named export で必ず提供する
// ================================================================

import { getPlanDataFromPage } from "map/plan_data"

let bound = false

const getPlanId = () => {
  const planIdFromMap = document.getElementById("map")?.dataset?.planId
  if (planIdFromMap) return planIdFromMap

  const planData = getPlanDataFromPage()
  return planData?.plan_id || planData?.id || null
}

// -------------------------------
// 開いている詳細(collapse)の退避/復元
// -------------------------------
const captureOpenSpotDetailIds = () => {
  const opened = document.querySelectorAll(".spot-detail.collapse.show[id]")
  return Array.from(opened).map((el) => el.id).filter(Boolean)
}

const restoreOpenSpotDetailIds = async (ids) => {
  if (!ids || ids.length === 0) return

  let Collapse = null
  try {
    ;({ Collapse } = await import("bootstrap"))
  } catch (_) {}

  ids.forEach((id) => {
    const collapseEl = document.getElementById(id)
    if (!collapseEl) return

    if (Collapse) {
      const instance = Collapse.getOrCreateInstance(collapseEl, { toggle: false })
      instance.show()
    } else {
      collapseEl.classList.add("show")
      collapseEl.style.height = "auto"
    }

    const safeId = typeof CSS !== "undefined" && CSS.escape ? CSS.escape(id) : id
    const toggles = document.querySelectorAll(
      `[data-bs-target="#${safeId}"],[href="#${safeId}"]`
    )
    toggles.forEach((btn) => {
      btn.classList.remove("collapsed")
      btn.setAttribute("aria-expanded", "true")
    })
  })
}

// -------------------------------
// planbar スクロール位置の退避/復元
// -------------------------------
const getPlanbarScrollEl = () => document.querySelector(".planbar__content")

const capturePlanbarScrollTop = () => {
  const el = getPlanbarScrollEl()
  return el ? el.scrollTop : 0
}

const restorePlanbarScrollTop = (scrollTop) => {
  const el = getPlanbarScrollEl()
  if (!el) return
  el.scrollTop = scrollTop || 0
}

// -------------------------------
// Turbo復元時だけ collapse のアニメを止める
// -------------------------------
const withNoCollapseAnimation = async (fn) => {
  const root = document.documentElement
  root.classList.add("no-collapse-anim")
  try {
    await fn()
  } finally {
    requestAnimationFrame(() => {
      root.classList.remove("no-collapse-anim")
    })
  }
}

const refreshPlanbar = async (planId) => {
  // ✅ 差し替え前に退避
  const openedSpotDetailIds = captureOpenSpotDetailIds()
  const scrollTop = capturePlanbarScrollTop()

  // ✅ 差し替え「直前」イベント（Sortable 側で destroy する用途）
  document.dispatchEvent(new CustomEvent("planbar:will-update"))

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

  // ✅ 差し替え後に復元（次フレームでDOMが落ち着いてから）
  requestAnimationFrame(() => {
    setTimeout(() => {
      // スクロール復元（先にやると体感が良い）
      restorePlanbarScrollTop(scrollTop)

      // collapse復元（Turbo復元時はアニメ無し）
      withNoCollapseAnimation(async () => {
        await restoreOpenSpotDetailIds(openedSpotDetailIds)
      })
    }, 0)
  })

  // ✅ 差し替え完了を通知（Sortable 等はこれで init し直す）
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

  document.addEventListener("plan:spots-reordered", async () => {
    const planId = getPlanId()
    console.log("[planbar_updater] caught plan:spots-reordered", { planId })
    if (!planId) return
    await refreshPlanbar(planId)
  })

  document.addEventListener("plan:spot-deleted", async (e) => {
    const planId = e?.detail?.planId || getPlanId()
    console.log("[planbar_updater] caught plan:spot-deleted", { planId, detail: e?.detail })
    if (!planId) return
    await refreshPlanbar(planId)
  })

  document.addEventListener("plan:plan-spot-toll-used-updated", async (e) => {
    const planId = getPlanId()
    console.log("[planbar_updater] caught plan:plan-spot-toll-used-updated", {
      planId,
      detail: e?.detail,
    })
    if (!planId) return
    await refreshPlanbar(planId)
  })
}