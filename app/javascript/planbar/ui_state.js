// app/javascript/planbar/ui_state.js
// ================================================================
// Planbar UI State（単一責務）
// 用途: planbar 内の UI 状態（collapse, memo/tags フォーム, goal point visibility）の
//       退避・復元を担当
// ================================================================

// -------------------------------
// planbar root 取得
// -------------------------------
export const getPlanbarRoot = () => document.querySelector(".planbar") || document

// -------------------------------
// Bootstrap Collapse 状態の退避/復元
// -------------------------------
export const captureOpenCollapseIds = () => {
  const root = getPlanbarRoot()
  const opened = root.querySelectorAll(".collapse.show[id]")
  return Array.from(opened).map((el) => el.id).filter(Boolean)
}

export const restoreOpenCollapseIds = async (ids) => {
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
// spot-block 内フォーム状態（memo/tags）退避/復元
// -------------------------------
export const captureSpotBlockUIStates = () => {
  const root = getPlanbarRoot()
  const blocks = root.querySelectorAll('.spot-block[data-plan-spot-id]')

  return Array.from(blocks)
    .map((block) => {
      const planSpotId = block.dataset.planSpotId
      if (!planSpotId) return null

      const memoEditor = block.querySelector('[data-plan-spot-memo-target="editor"]')
      const tagsForm = block.querySelector('[data-plan-spot-tags-target="form"]')

      const memoOpen = memoEditor ? !memoEditor.classList.contains("d-none") : false
      const tagsOpen = tagsForm ? !tagsForm.classList.contains("d-none") : false

      if (!memoOpen && !tagsOpen) return null
      return { planSpotId, memoOpen, tagsOpen }
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

export const restoreSpotBlockUIStates = async (states) => {
  if (!states || states.length === 0) return

  for (const st of states) {
    const block = document.querySelector(`.spot-block[data-plan-spot-id="${st.planSpotId}"]`)
    if (!block) continue

    await ensureSpotDetailOpen(block)

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
// 帰宅地点トグル状態の退避/復元
// -------------------------------
export const captureGoalPointVisibilityState = () => {
  const section = document.querySelector(".goal-point-section")
  if (!section) return null

  const switchEl =
    section.querySelector('[data-goal-point-visibility-target="switch"]') ||
    document.getElementById("goal-point-visibility-switch")

  const blockArea = section.querySelector('[data-goal-point-visibility-target="blockArea"]')
  if (!switchEl || !blockArea) return null

  const mapEl = document.getElementById("map")
  const mapGoalPointVisible = mapEl?.dataset?.goalPointVisible === "true"

  return {
    checked: !!switchEl.checked,
    hidden: !!blockArea.hidden,
    bodyVisible: document.body.classList.contains("goal-point-visible"),
    mapGoalPointVisible,
  }
}

export const restoreGoalPointVisibilityState = (state) => {
  if (!state) return

  const section = document.querySelector(".goal-point-section")
  if (!section) return

  const switchEl =
    section.querySelector('[data-goal-point-visibility-target="switch"]') ||
    document.getElementById("goal-point-visibility-switch")

  const blockArea = section.querySelector('[data-goal-point-visibility-target="blockArea"]')
  if (switchEl) switchEl.checked = !!state.checked
  if (blockArea) blockArea.hidden = !!state.hidden

  if (state.bodyVisible) document.body.classList.add("goal-point-visible")
  else document.body.classList.remove("goal-point-visible")

  const mapEl = document.getElementById("map")
  if (mapEl) {
    mapEl.dataset.goalPointVisible = state.mapGoalPointVisible ? "true" : "false"
  }
}

// -------------------------------
// 出発時刻の body class 更新
// -------------------------------
export const updateDepartureTimeClass = () => {
  const departureTimeSet = document.querySelector(".start-departure-time--set")
  document.body.classList.toggle("departure-time-unset", !departureTimeSet)
}

// -------------------------------
// Collapse アニメーション無効化ヘルパー
// -------------------------------
export const withNoCollapseAnimation = async (fn) => {
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
