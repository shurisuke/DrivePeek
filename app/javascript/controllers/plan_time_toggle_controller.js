// app/javascript/controllers/plan_time_toggle_controller.js
// ================================================================
// 時刻表示のON/OFFトグル
// - body.plan-time-open を切り替える（表示状態の唯一の真実）
// - Turbo Frame(planbar) 再描画後に
//   1) 開閉状態（body class）を復元
//   2) scrollTop を復元
//   3) スクロールコンテナ幅を再適用（CSSが効かない時の保険で inline も使う）
// ================================================================

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    planbarSelector: { type: String, default: ".planbar" },
    frameId: { type: String, default: "planbar" },
    storageKey: { type: String, default: "drive_peek:plan_time_open" },
  }

  connect() {
    console.log("[plan-time-toggle] connect")

    this.boundOnTabClick = this.onTabClick.bind(this)
    this.boundBeforeFrameRender = this.beforeFrameRender.bind(this)
    this.boundAfterFrameRender = this.afterFrameRender.bind(this)

    this.checkVisibility()
    this.restoreOpenState()
    this.updateDepartureTimeClass()

    document.addEventListener("click", this.boundOnTabClick)

    // ✅ Turbo Frame の差し替えをフック（これが安定）
    document.addEventListener("turbo:before-frame-render", this.boundBeforeFrameRender)
    document.addEventListener("turbo:frame-render", this.boundAfterFrameRender)
  }

  disconnect() {
    document.removeEventListener("click", this.boundOnTabClick)
    document.removeEventListener("turbo:before-frame-render", this.boundBeforeFrameRender)
    document.removeEventListener("turbo:frame-render", this.boundAfterFrameRender)
  }

  // ------------------------------------------------------------
  // UI操作
  // ------------------------------------------------------------
  toggle() {
    console.log("[plan-time-toggle] toggle clicked")

    if (!this.isPlanActive()) {
      console.log("[plan-time-toggle] not plan tab, abort")
      return
    }

    const nextOpen = !document.body.classList.contains("plan-time-open")
    this.setOpen(nextOpen, { save: true })
  }

  setOpen(isOpen, { save = false } = {}) {
    console.log("[plan-time-toggle] setOpen =>", isOpen)

    document.body.classList.toggle("plan-time-open", isOpen)

    // ✅ 出発時刻の状態に応じて departure-time-unset クラスを切り替え
    this.updateDepartureTimeClass()

    // ボタン見た目
    const fab = this.element.querySelector(".plan-time-fab")
    if (fab) {
      fab.classList.toggle("is-active", isOpen)
      fab.setAttribute("aria-pressed", String(isOpen))
    }

    // ✅ 幅（CSSが効くのが基本、効かない時の保険で inline をセット）
    this.applyScrollWidthFallback(isOpen)

    if (save) this.saveOpenState(isOpen)
  }

  // 出発時刻が未設定なら body.departure-time-unset を付与
  updateDepartureTimeClass() {
    const departureTimeSet = document.querySelector(".start-departure-time--set")
    document.body.classList.toggle("departure-time-unset", !departureTimeSet)
  }

  saveOpenState(isOpen) {
    try {
      localStorage.setItem(this.storageKeyValue, isOpen ? "1" : "0")
      console.log("[plan-time-toggle] save storage", { isOpen })
    } catch (e) {
      console.log("[plan-time-toggle] save storage failed", e)
    }
  }

  restoreOpenState() {
    if (!this.isPlanActive()) {
      console.log("[plan-time-toggle] restore: not plan tab -> close")
      this.setOpen(false, { save: false })
      return
    }

    let stored = null
    try {
      stored = localStorage.getItem(this.storageKeyValue)
    } catch (e) {
      console.log("[plan-time-toggle] restore: storage read failed", e)
    }

    if (stored === null) {
      console.log("[plan-time-toggle] restore: no storage")
      this.setOpen(false, { save: false })
      return
    }

    const isOpen = stored === "1"
    console.log("[plan-time-toggle] restore:", { isOpen })
    this.setOpen(isOpen, { save: false })
  }

  // ------------------------------------------------------------
  // Turbo Frame 再描画対応（スクロール状態を保持）
  // ------------------------------------------------------------
  beforeFrameRender(event) {
    const frame = event.target
    if (!(frame instanceof HTMLElement)) return
    if (frame.id !== this.frameIdValue) return

    // 差し替え直前に scrollTop を退避
    const scroll = this.findPlanbarScroll()
    this.cachedScrollTop = scroll ? scroll.scrollTop : 0

    console.log("[plan-time-toggle] turbo:before-frame-render", {
      cachedScrollTop: this.cachedScrollTop,
      hasScroll: !!scroll,
    })
  }

  afterFrameRender(event) {
    const frame = event.target
    if (!(frame instanceof HTMLElement)) return
    if (frame.id !== this.frameIdValue) return

    // ✅ 差し替え後：状態を必ず再適用
    const isOpen = document.body.classList.contains("plan-time-open")

    console.log("[plan-time-toggle] turbo:frame-render -> reapply", { isOpen })

    // 1) 幅の再適用（CSS/inline保険）
    this.applyScrollWidthFallback(isOpen)

    // 2) 出発時刻の状態を再適用
    this.updateDepartureTimeClass()

    // 3) scrollTop 復元
    const scroll = this.findPlanbarScroll()
    if (scroll) {
      scroll.scrollTop = this.cachedScrollTop || 0
    }

    console.log("[plan-time-toggle] turbo:frame-render -> restored", {
      restoredScrollTop: this.cachedScrollTop || 0,
      hasScroll: !!scroll,
    })
  }

  // CSSが効けば不要だが、再描画直後に一瞬効かず崩れるケースがあるので保険で入れる
  applyScrollWidthFallback(isOpen) {
    const scroll = this.findPlanbarScroll()
    if (!scroll) return

    // ✅ close の時は「必ず解除」して CSS に戻す
    if (!isOpen) {
      scroll.style.width = ""
      return
    }

    // ✅ open の時だけ rail分の幅を確実に確保
    scroll.style.width = "calc(var(--planbar-width) + var(--rail-width))"

    // ついでに再描画直後のレイアウト確定を促す（スクロール不能対策の保険）
    // ※副作用が少ない read
    void scroll.offsetHeight
  }

  findPlanbarScroll() {
    const planbar = document.querySelector(this.planbarSelectorValue)
    return planbar ? planbar.querySelector(".planbar__content-scroll") : null
  }

  // ------------------------------------------------------------
  // Planタブ判定（既存ロジック）
  // ------------------------------------------------------------
  onTabClick(event) {
    const tabBtn = event.target.closest("[data-tab]")
    if (!tabBtn) return

    requestAnimationFrame(() => {
      this.checkVisibility()
      this.closeIfNotPlan()
    })
  }

  checkVisibility() {
    const shouldShow = this.isPlanActive()
    this.element.hidden = !shouldShow
    console.log("[plan-time-toggle] checkVisibility", { shouldShow })
  }

  closeIfNotPlan() {
    if (this.isPlanActive()) return

    document.body.classList.remove("plan-time-open")

    const fab = this.element.querySelector(".plan-time-fab")
    if (fab) {
      fab.classList.remove("is-active")
      fab.setAttribute("aria-pressed", "false")
    }

    // 念のため、幅の上書きも解除
    this.applyScrollWidthFallback(false)

    console.log("[plan-time-toggle] closeIfNotPlan")
  }

  isPlanActive() {
    const planbar = document.querySelector(this.planbarSelectorValue)
    if (!planbar) return false

    const planBtn = planbar.querySelector('[data-tab="plan"]')
    return !!planBtn && planBtn.classList.contains("active")
  }
}