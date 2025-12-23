// app/javascript/plans/debug_dom.js
// ================================================================
// 単一責務: planbar / time-rail 周りのDOM状態をログで可視化する
// 用途: planbar再描画後に「レールが混入/スクロール不能」になる原因の特定
// ================================================================

const px = (v) => (typeof v === "number" ? `${Math.round(v)}px` : String(v || ""))

export const logPlanbarTimeRailState = (label = "") => {
  try {
    const body = document.body
    const isOpen = body.classList.contains("plan-time-open")

    const planForm = document.querySelector(".plan-form")
    const planbar = document.querySelector(".planbar")
    const scroll = planbar?.querySelector(".planbar__content-scroll")
    const blocks = planbar?.querySelector(".planbar__blocks")

    const rect = (el) => (el ? el.getBoundingClientRect() : null)
    const cs = (el) => (el ? window.getComputedStyle(el) : null)

    const scrollCS = cs(scroll)
    const planbarCS = cs(planbar)

    // 重要: railのDOMが planbar の中に混入していないか
    const railInsidePlanbar = planbar ? planbar.querySelectorAll(".block-time-panel").length : 0
    const railInsideScroll = scroll ? scroll.querySelectorAll(".block-time-panel").length : 0

    console.groupCollapsed(
      `%c[time-rail][state] ${label}  open=${isOpen}`,
      "color:#1d4928;font-weight:bold;"
    )

    console.log("body.plan-time-open =", isOpen)
    console.log("planForm =", !!planForm, rect(planForm))
    console.log("planbar =", !!planbar, rect(planbar), planbarCS && { overflow: planbarCS.overflow })
    console.log(
      "scroll =",
      !!scroll,
      rect(scroll),
      scrollCS && {
        width: scrollCS.width,
        overflowY: scrollCS.overflowY,
        position: scrollCS.position
      }
    )
    console.log("blocks =", !!blocks, rect(blocks))

    console.log("block-time-panel count in planbar =", railInsidePlanbar)
    console.log("block-time-panel count in scroll =", railInsideScroll)

    // スクロール不能の典型: height/overflowが壊れる
    if (scroll) {
      console.log("scroll.scrollHeight =", scroll.scrollHeight)
      console.log("scroll.clientHeight =", scroll.clientHeight)
      console.log("scroll.scrollTop =", scroll.scrollTop)
    }

    console.groupEnd()
  } catch (e) {
    console.warn("[time-rail][state] log failed", e)
  }
}