// app/javascript/plans/planbar_updater.js
//
// ================================================================
// Planbar Updater（単一責務）
// 用途: planbar を Turbo Stream で差し替えて、通知イベントを投げるだけ。
// ✅ 改良：空白ゼロ
//   - fetch中は旧UIを見せたまま操作だけ止める
//   - 差し替え〜復元中は「旧UIのスナップショット」を上に被せて空白を消す
//   - 裏では visibility:hidden でガタつきを隠して復元する
//   - planbar内の collapse(show) をすべて復元（StartPoint/Spot/Goal など）
//   - spot-block 内のフォーム状態（settings/memo/tags）を復元
//   - planbar__content のスクロール位置も復元（アンカー方式）
// ✅ 追加：帰宅地点トグル（switch/hidden/body class）も退避・即復元（ガタつき対策）
//   - Turbo差し替え後に controller が “後から” hidden を触って揺れるのを防ぐ
//   - Turbo復元時はcollapseのアニメーションを無効化する
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
// planbar root / scroll element
// -------------------------------
const getPlanbarRoot = () => {
  const scroll = document.querySelector(".planbar__content")
  return scroll || document
}

const getPlanbarScrollEl = () => document.querySelector(".planbar__content")

// -------------------------------
// ✅ fetch中：見た目は残したまま「操作だけ」止める
// -------------------------------
const lockPlanbarUI = () => {
  const el = getPlanbarScrollEl()
  if (!el) return
  el.style.setProperty("pointer-events", "none", "important")
  el.style.setProperty("user-select", "none", "important")
}

const unlockPlanbarUI = () => {
  const el = getPlanbarScrollEl()
  if (!el) return
  el.style.removeProperty("pointer-events")
  el.style.removeProperty("user-select")
}

// -------------------------------
// ✅ DOM差し替え〜復元中だけ planbar を隠す（裏で作業する）
// -------------------------------
const hidePlanbar = () => {
  const el = getPlanbarScrollEl()
  if (!el) return
  el.style.setProperty("visibility", "hidden", "important")
}

const showPlanbar = () => {
  const el = getPlanbarScrollEl()
  if (!el) return
  el.style.removeProperty("visibility")
}

// -------------------------------
// ✅ 更新中だけ scroll anchoring を無効化（勝手にズレるのを抑える）
// -------------------------------
const beginPlanbarUpdate = () => {
  const el = getPlanbarScrollEl()
  if (!el) return

  if (el.dataset.prevScrollBehavior == null) {
    el.dataset.prevScrollBehavior = el.style.scrollBehavior || ""
  }
  if (el.dataset.prevOverflowAnchor == null) {
    el.dataset.prevOverflowAnchor = el.style.overflowAnchor || ""
  }

  el.style.scrollBehavior = "auto"
  el.style.overflowAnchor = "none"

  hidePlanbar()
}

const endPlanbarUpdate = () => {
  const el = getPlanbarScrollEl()
  if (!el) return

  el.style.scrollBehavior = el.dataset.prevScrollBehavior || ""
  el.style.overflowAnchor = el.dataset.prevOverflowAnchor || ""
  delete el.dataset.prevScrollBehavior
  delete el.dataset.prevOverflowAnchor

  showPlanbar()
}

// ================================================================
// ✅ 空白ゼロのための “スナップショット”
// - 旧 planbar__content を固定位置で画面上に被せる
// - duplicate id / data-controller を除去して副作用をゼロにする
// ================================================================
let planbarSnapshotEl = null

const sanitizeSnapshot = (root) => {
  if (!root) return

  root.removeAttribute("id")
  root.querySelectorAll("[id]").forEach((el) => el.removeAttribute("id"))

  root.removeAttribute("data-controller")
  root.querySelectorAll("[data-controller]").forEach((el) => el.removeAttribute("data-controller"))

  root.removeAttribute("data-action")
  root.querySelectorAll("[data-action]").forEach((el) => el.removeAttribute("data-action"))

  root.setAttribute("inert", "")
  root.setAttribute("aria-hidden", "true")
}

const createPlanbarSnapshot = () => {
  const src = getPlanbarScrollEl()
  if (!src) return null

  const rect = src.getBoundingClientRect()

  const clone = src.cloneNode(true)
  sanitizeSnapshot(clone)

  // ✅ サブピクセルで左右に“ビクッ”としやすいので整数化（軽いが効く）
  const top = Math.round(rect.top)
  const left = Math.round(rect.left)
  const width = Math.round(rect.width)
  const height = Math.round(rect.height)

  clone.style.position = "fixed"
  clone.style.top = `${top}px`
  clone.style.left = `${left}px`
  clone.style.width = `${width}px`
  clone.style.height = `${height}px`
  clone.style.margin = "0"
  clone.style.zIndex = "999999"
  clone.style.pointerEvents = "none"

  // ✅ ここ重要：スクロールバー有無で幅が変わると“左右ガタつき”になる
  // overflow:hidden だと見た目の折返し/幅が変わりやすいので auto/scroll に寄せる
  clone.style.overflowY = "scroll"
  clone.style.overflowX = "hidden"
  clone.style.scrollbarGutter = "stable"
  clone.style.boxSizing = "border-box"

  clone.style.background = "#fff"

  document.body.appendChild(clone)

  try {
    clone.scrollTop = src.scrollTop || 0
  } catch (_) {}

  return clone
}

const removePlanbarSnapshot = () => {
  if (!planbarSnapshotEl) return
  planbarSnapshotEl.remove()
  planbarSnapshotEl = null
}

// -------------------------------
// ✅ planbar内の collapse(show) 退避/復元（StartPoint/Spot/Goal 全対応）
// -------------------------------
const captureOpenCollapseIds = () => {
  const root = getPlanbarRoot()
  const opened = root.querySelectorAll(".collapse.show[id]")
  return Array.from(opened).map((el) => el.id).filter(Boolean)
}

const restoreOpenCollapseIds = async (ids) => {
  if (!ids || ids.length === 0) return

  let Collapse = null
  try {
    ;({ Collapse } = await import("bootstrap"))
  } catch (_) {}

  ids.forEach((id) => {
    const el = document.getElementById(id)
    if (!el) return

    if (Collapse) {
      Collapse.getOrCreateInstance(el, { toggle: false }).show()
    } else {
      el.classList.add("show")
      el.style.height = "auto"
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
// ✅ spot-block 内フォーム状態（settings/memo/tags）退避/復元
// -------------------------------
const captureSpotBlockUIStates = () => {
  const root = getPlanbarRoot()
  const blocks = root.querySelectorAll('.spot-block[data-plan-spot-id]')

  return Array.from(blocks)
    .map((block) => {
      const planSpotId = block.dataset.planSpotId
      if (!planSpotId) return null

      const settingsPanel = block.querySelector('[data-plan-spot-settings-target="panel"]')
      const memoEditor = block.querySelector('[data-plan-spot-memo-target="editor"]')
      const tagsForm = block.querySelector('[data-plan-spot-tags-target="form"]')

      const settingsOpen = settingsPanel ? !settingsPanel.classList.contains("d-none") : false
      const memoOpen = memoEditor ? !memoEditor.classList.contains("d-none") : false
      const tagsOpen = tagsForm ? !tagsForm.classList.contains("d-none") : false

      if (!settingsOpen && !memoOpen && !tagsOpen) return null
      return { planSpotId, settingsOpen, memoOpen, tagsOpen }
    })
    .filter(Boolean)
}

const ensureSpotDetailOpen = async (block) => {
  const collapseEl = block.querySelector(".spot-detail.collapse[id], .collapse[id]")
  if (!collapseEl) return
  if (collapseEl.classList.contains("show")) return

  let Collapse = null
  try {
    ;({ Collapse } = await import("bootstrap"))
  } catch (_) {}

  if (Collapse) {
    Collapse.getOrCreateInstance(collapseEl, { toggle: false }).show()
  } else {
    collapseEl.classList.add("show")
    collapseEl.style.height = "auto"
  }

  const id = collapseEl.id
  const safeId = typeof CSS !== "undefined" && CSS.escape ? CSS.escape(id) : id
  const toggles = document.querySelectorAll(
    `[data-bs-target="#${safeId}"],[href="#${safeId}"]`
  )
  toggles.forEach((btn) => {
    btn.classList.remove("collapsed")
    btn.setAttribute("aria-expanded", "true")
  })
}

const restoreSpotBlockUIStates = async (states) => {
  if (!states || states.length === 0) return

  for (const st of states) {
    const block = document.querySelector(`.spot-block[data-plan-spot-id="${st.planSpotId}"]`)
    if (!block) continue

    await ensureSpotDetailOpen(block)

    const settingsPanel = block.querySelector('[data-plan-spot-settings-target="panel"]')
    if (settingsPanel) settingsPanel.classList.toggle("d-none", !st.settingsOpen)

    const settingsToggle = block.querySelector('[data-plan-spot-settings-target="toggle"]')
    if (settingsToggle) {
      settingsToggle.setAttribute("aria-expanded", st.settingsOpen ? "true" : "false")
    }

    const memoEditor = block.querySelector('[data-plan-spot-memo-target="editor"]')
    const memoDisplay = block.querySelector('[data-plan-spot-memo-target="memoDisplay"]')
    if (memoEditor) memoEditor.classList.toggle("d-none", !st.memoOpen)
    if (memoDisplay) memoDisplay.classList.toggle("is-editing", st.memoOpen)

    const tagsForm = block.querySelector('[data-plan-spot-tags-target="form"]')
    if (tagsForm) tagsForm.classList.toggle("d-none", !st.tagsOpen)

    const chips = block.querySelector(".spot-tags")
    if (chips) chips.classList.toggle("is-editing", st.tagsOpen)
  }
}

// -------------------------------
// ✅ 追加：帰宅地点トグル（switch/hidden/body class）退避/復元
// - これが「後から切り替わる」と planbar 高さが変わってガタつく
// -------------------------------
const captureGoalPointVisibilityState = () => {
  const section = document.querySelector(".goal-point-section")
  if (!section) return null

  const switchEl =
    section.querySelector('[data-goal-point-visibility-target="switch"]') ||
    document.getElementById("goal-point-visibility-switch")

  const blockArea = section.querySelector('[data-goal-point-visibility-target="blockArea"]')
  if (!switchEl || !blockArea) return null

  return {
    checked: !!switchEl.checked,
    hidden: !!blockArea.hidden,
    bodyVisible: document.body.classList.contains("goal-point-visible"),
  }
}

const restoreGoalPointVisibilityState = (state) => {
  if (!state) return

  const section = document.querySelector(".goal-point-section")
  if (!section) return

  const switchEl =
    section.querySelector('[data-goal-point-visibility-target="switch"]') ||
    document.getElementById("goal-point-visibility-switch")

  const blockArea = section.querySelector('[data-goal-point-visibility-target="blockArea"]')
  if (switchEl) switchEl.checked = !!state.checked
  if (blockArea) blockArea.hidden = !!state.hidden

  // ✅ CSSが body.goal-point-visible に依存してるので、ここも即復元して“揺れ”を止める
  if (state.bodyVisible) document.body.classList.add("goal-point-visible")
  else document.body.classList.remove("goal-point-visible")
}

// -------------------------------
// ✅ planbar スクロール位置の退避/復元（ズレない方式）
// -------------------------------
const findScrollAnchor = (scrollEl) => {
  if (!scrollEl) return null

  const rect = scrollEl.getBoundingClientRect()
  const x = rect.left + 24
  const y = rect.top + 24

  let el = document.elementFromPoint(x, y)
  if (!el) return null
  if (!scrollEl.contains(el)) return null

  const spotBlock = el.closest('.spot-block[data-plan-spot-id]')
  if (spotBlock) {
    return {
      type: "plan_spot",
      key: spotBlock.dataset.planSpotId,
      offset: spotBlock.getBoundingClientRect().top - rect.top,
    }
  }

  const idEl = el.closest("[id]")
  if (idEl && idEl.id) {
    return {
      type: "id",
      key: idEl.id,
      offset: idEl.getBoundingClientRect().top - rect.top,
    }
  }

  return null
}

const capturePlanbarScrollState = () => {
  const el = getPlanbarScrollEl()
  if (!el) return { kind: "top", scrollTop: 0 }

  const anchor = findScrollAnchor(el)
  if (anchor) return { kind: "anchor", ...anchor }

  return { kind: "scrollTop", scrollTop: el.scrollTop || 0 }
}

const restorePlanbarScrollState = (state) => {
  const el = getPlanbarScrollEl()
  if (!el || !state) return

  if (state.kind === "anchor") {
    const rect = el.getBoundingClientRect()

    let target = null
    if (state.type === "plan_spot") {
      target = el.querySelector(`.spot-block[data-plan-spot-id="${state.key}"]`)
    } else if (state.type === "id") {
      const key = typeof CSS !== "undefined" && CSS.escape ? CSS.escape(state.key) : state.key
      target = document.getElementById(key) || el.querySelector(`#${key}`)
    }

    if (target) {
      const currentTop = target.getBoundingClientRect().top - rect.top
      const delta = currentTop - (state.offset || 0)
      el.scrollTop = el.scrollTop + delta
      return
    }
  }

  if (state.kind === "scrollTop") {
    el.scrollTop = state.scrollTop || 0
    return
  }

  el.scrollTop = 0
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
  const openCollapseIds = captureOpenCollapseIds()
  const spotBlockStates = captureSpotBlockUIStates()
  const scrollState = capturePlanbarScrollState()

  // ✅ 追加：帰宅地点トグル状態も退避（ガタつき対策）
  const goalPointState = captureGoalPointVisibilityState()

  document.dispatchEvent(new CustomEvent("planbar:will-update"))

  lockPlanbarUI()

  let html = null
  try {
    const res = await fetch(`/plans/${planId}/planbar`, {
      headers: { Accept: "text/vnd.turbo-stream.html" },
      credentials: "same-origin",
    })
    if (!res.ok) {
      console.warn("[planbar_updater] refreshPlanbar failed", { planId, status: res.status })
      return
    }
    html = await res.text()
  } finally {
    // unlockは最後に
  }

  if (!window.Turbo) {
    console.error("[planbar_updater] Turbo is not available on window")
    unlockPlanbarUI()
    return
  }

  planbarSnapshotEl = createPlanbarSnapshot()
  beginPlanbarUpdate()

  try {
    await withNoCollapseAnimation(async () => {
      window.Turbo.renderStreamMessage(html)

      // Turbo差し替え後は新しい .planbar__content になるので、もう一度隠す
      hidePlanbar()

      // ✅ ここで “即” 復元しておく（controllerが後から触って揺れるのを潰す）
      restoreGoalPointVisibilityState(goalPointState)

      await new Promise((r) => requestAnimationFrame(() => r()))

      await restoreOpenCollapseIds(openCollapseIds)
      await restoreSpotBlockUIStates(spotBlockStates)

      restorePlanbarScrollState(scrollState)

      // 2フレーム補正
      await new Promise((r) => requestAnimationFrame(() => r()))
      await new Promise((r) => requestAnimationFrame(() => r()))
      restorePlanbarScrollState(scrollState)
    })

    document.dispatchEvent(new CustomEvent("planbar:updated"))
    document.dispatchEvent(new CustomEvent("map:route-updated"))
  } finally {
    endPlanbarUpdate()
    removePlanbarSnapshot()
    unlockPlanbarUI()
  }
}

export const bindPlanbarRefresh = () => {
  if (bound) return
  bound = true

  document.addEventListener("plan:spot-added", async () => {
    const planId = getPlanId()
    if (!planId) return
    await refreshPlanbar(planId)
  })

  document.addEventListener("plan:spots-reordered", async () => {
    const planId = getPlanId()
    if (!planId) return
    await refreshPlanbar(planId)
  })

  document.addEventListener("plan:spot-deleted", async (e) => {
    const planId = e?.detail?.planId || getPlanId()
    if (!planId) return
    await refreshPlanbar(planId)
  })

  document.addEventListener("plan:plan-spot-toll-used-updated", async () => {
    const planId = getPlanId()
    if (!planId) return
    await refreshPlanbar(planId)
  })
}