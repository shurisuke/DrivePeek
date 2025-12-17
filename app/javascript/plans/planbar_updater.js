// app/javascript/plans/planbar_updater.js
//
// ================================================================
// Planbar Updater（単一責務）
// 用途: planbar を Turbo Stream で差し替えて、通知イベントを投げるだけ。
// 追加: planbar差し替え前後で「開いていたスポット詳細トグル(collapse)」を復元する
// 追加: Turbo復元時はcollapseのアニメーションを無効化する
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

// ================================================================
// ✅ planbar差し替えで消える「開閉状態」を退避/復元する
// - spot-detail は Bootstrap collapse を想定（.collapse.show が開いている状態）
// - id (例: spotDetail-123) をキーにして復元する
// ================================================================
const captureOpenSpotDetailIds = () => {
  const opened = document.querySelectorAll(".spot-detail.collapse.show[id]")
  return Array.from(opened)
    .map((el) => el.id)
    .filter(Boolean)
}

const restoreOpenSpotDetailIds = async (ids) => {
  if (!ids || ids.length === 0) return

  // Bootstrap が import できるなら show() で復元（推奨）
  let Collapse = null
  try {
    ;({ Collapse } = await import("bootstrap"))
  } catch (_) {
    // fallback: クラス操作のみで見た目だけ復元
  }

  ids.forEach((id) => {
    const collapseEl = document.getElementById(id)
    if (!collapseEl) return

    if (Collapse) {
      const instance = Collapse.getOrCreateInstance(collapseEl, { toggle: false })
      instance.show() // ← ここで通常はアニメが走る（Turbo復元時はCSSで抑止）
    } else {
      collapseEl.classList.add("show")
      collapseEl.style.height = "auto"
    }

    // トグルボタン側も整合させる（aria / collapsedクラス）
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

// ================================================================
// ✅ Turbo復元時だけ collapse のアニメを止める
// - documentElement に一時クラスを付けて、.collapsing の transition を殺す
// ================================================================
const withNoCollapseAnimation = async (fn) => {
  const root = document.documentElement
  root.classList.add("no-collapse-anim")

  try {
    await fn()
  } finally {
    // 復元処理が終わった次フレームで戻す（通常操作のアニメは維持）
    requestAnimationFrame(() => {
      root.classList.remove("no-collapse-anim")
    })
  }
}

const refreshPlanbar = async (planId) => {
  // ✅ 差し替え前に「今開いてる詳細」を退避
  const openedSpotDetailIds = captureOpenSpotDetailIds()

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

  // ✅ 差し替え後に「開いてた詳細」を復元（Turbo復元時はアニメ無し）
  requestAnimationFrame(() => {
    setTimeout(() => {
      withNoCollapseAnimation(async () => {
        await restoreOpenSpotDetailIds(openedSpotDetailIds)
      })
    }, 0)
  })

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

  document.addEventListener("plan:spots-reordered", async () => {
    const planId = getPlanId()
    console.log("[planbar_updater] caught plan:spots-reordered", { planId })
    if (!planId) return
    await refreshPlanbar(planId)
  })

  document.addEventListener("plan:plan-spot-toll-used-updated", async (e) => {
    const planId = getPlanId()
    console.log("[planbar_updater] caught plan:plan-spot-toll-used-updated", { planId, detail: e?.detail })
    if (!planId) return
    await refreshPlanbar(planId)
  })
}