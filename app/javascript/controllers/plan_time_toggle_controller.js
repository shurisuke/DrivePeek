// app/javascript/controllers/plan_time_toggle_controller.js
// ================================================================
// 時刻表示のON/OFFトグル
// - body.plan-time-open を切り替える（表示状態の唯一の真実）
// ================================================================

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    navibarSelector: { type: String, default: ".navibar" },
    storageKey: { type: String, default: "drive_peek:plan_time_open" },
  }

  connect() {
    this.boundOnTabClick = this.onTabClick.bind(this)
    this.boundOnNavibarUpdated = this.onNavibarUpdated.bind(this)

    this.checkVisibility()
    this.restoreOpenState()
    this.updateDepartureTimeClass()

    document.addEventListener("click", this.boundOnTabClick)
    // ✅ turbo_stream 更新後に状態を再適用
    document.addEventListener("navibar:updated", this.boundOnNavibarUpdated)
  }

  disconnect() {
    document.removeEventListener("click", this.boundOnTabClick)
    document.removeEventListener("navibar:updated", this.boundOnNavibarUpdated)
  }

  // turbo_stream で DOM が更新された後に呼ばれる
  onNavibarUpdated() {
    const isOpen = document.body.classList.contains("plan-time-open")

    // 出発時刻の状態を再適用
    this.updateDepartureTimeClass()

    // 幅の再適用（時刻レール表示中の場合）
    this.applyScrollWidthFallback(isOpen)
  }

  // ------------------------------------------------------------
  // UI操作
  // ------------------------------------------------------------
  toggle() {
    if (!this.isPlanActive()) return

    const nextOpen = !document.body.classList.contains("plan-time-open")
    this.setOpen(nextOpen, { save: true })
  }

  setOpen(isOpen, { save = false } = {}) {
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
    } catch (_) {
      // localStorage が使えない場合は無視
    }
  }

  restoreOpenState() {
    if (!this.isPlanActive()) {
      this.setOpen(false, { save: false })
      return
    }

    let stored = null
    try {
      stored = localStorage.getItem(this.storageKeyValue)
    } catch (_) {
      // localStorage が使えない場合は無視
    }

    if (stored === null) {
      this.setOpen(false, { save: false })
      return
    }

    const isOpen = stored === "1"
    this.setOpen(isOpen, { save: false })
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
    scroll.style.width = "calc(var(--navibar-width) + var(--rail-width))"

    // ついでに再描画直後のレイアウト確定を促す（スクロール不能対策の保険）
    // ※副作用が少ない read
    void scroll.offsetHeight
  }

  findPlanbarScroll() {
    const navibar = document.querySelector(this.navibarSelectorValue)
    return navibar ? navibar.querySelector(".navibar__content-scroll") : null
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
  }

  isPlanActive() {
    const navibar = document.querySelector(this.navibarSelectorValue)
    if (!navibar) return false

    const planBtn = navibar.querySelector('[data-tab="plan"]')
    return !!planBtn && planBtn.classList.contains("active")
  }
}