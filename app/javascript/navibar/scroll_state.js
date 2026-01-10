// app/javascript/navibar/scroll_state.js
// ================================================================
// Planbar Scroll State（単一責務）
// 用途: navibar のスクロール位置の退避・復元を担当
//       アンカー方式でズレを最小化
// ================================================================

// -------------------------------
// スクロール要素の取得
// -------------------------------
export const getPlanbarScrollEl = () =>
  document.querySelector(".navibar__content-scroll") ||
  document.querySelector(".navibar__content") ||
  null

// -------------------------------
// UI ロック/アンロック（更新中の操作抑制）
// -------------------------------
export const lockPlanbarUI = () => {
  const el = getPlanbarScrollEl()
  if (!el) return
  el.style.setProperty("pointer-events", "none", "important")
  el.style.setProperty("user-select", "none", "important")
}

export const unlockPlanbarUI = () => {
  const el = getPlanbarScrollEl()
  if (!el) return
  el.style.removeProperty("pointer-events")
  el.style.removeProperty("user-select")
}

// -------------------------------
// 更新中のスクロールアンカリング制御
// -------------------------------
export const beginPlanbarUpdate = () => {
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
}

export const endPlanbarUpdate = () => {
  const el = getPlanbarScrollEl()
  if (!el) return

  el.style.scrollBehavior = el.dataset.prevScrollBehavior || ""
  el.style.overflowAnchor = el.dataset.prevOverflowAnchor || ""
  delete el.dataset.prevScrollBehavior
  delete el.dataset.prevOverflowAnchor
}

// -------------------------------
// スクロール位置の退避/復元（アンカー方式）
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

export const capturePlanbarScrollState = () => {
  const el = getPlanbarScrollEl()
  if (!el) return { kind: "top", scrollTop: 0 }

  const anchor = findScrollAnchor(el)
  if (anchor) return { kind: "anchor", ...anchor }

  return { kind: "scrollTop", scrollTop: el.scrollTop || 0 }
}

export const restorePlanbarScrollState = (state) => {
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
// 最下部へスクロール（スポット追加後用）
// -------------------------------
export const scrollToBottom = () => {
  requestAnimationFrame(() => {
    requestAnimationFrame(() => {
      const scrollEl = getPlanbarScrollEl()
      if (scrollEl) {
        scrollEl.scrollTop = scrollEl.scrollHeight
      }
    })
  })
}
