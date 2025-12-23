// app/javascript/controllers/plan_time_toggle_controller.js
// ================================================================
// 時刻表示のON/OFFトグル
// - body.plan-time-open を切り替える
// - Planタブの時だけ表示（navibar と連携）
// ================================================================

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    planbarSelector: { type: String, default: ".planbar" }
  }

  connect() {
    console.log("[plan-time-toggle] connect")

    // ✅ removeEventListener が効くように、bindした参照を保持する
    this.boundOnTabClick = this.onTabClick.bind(this)

    // Planタブかどうかを監視
    this.checkVisibility()

    // タブ切り替えを監視
    document.addEventListener("click", this.boundOnTabClick)
  }

  disconnect() {
    if (this.boundOnTabClick) {
      document.removeEventListener("click", this.boundOnTabClick)
    }
  }

  toggle() {
    console.log("[plan-time-toggle] toggle clicked")

    if (!this.isPlanActive()) {
      console.log("[plan-time-toggle] not plan tab, abort")
      return
    }

    document.body.classList.toggle("plan-time-open")
    const isOpen = document.body.classList.contains("plan-time-open")

    console.log("[plan-time-toggle] plan-time-open", { isOpen })

    // ボタンの状態を更新
    const fab = this.element.querySelector(".plan-time-fab")
    if (fab) {
      fab.classList.toggle("is-active", isOpen)
      fab.setAttribute("aria-pressed", String(isOpen))
    }

    // ✅ カスタムイベントを発火してレールに通知（ラグ解消）
    document.body.dispatchEvent(new CustomEvent("plan-time-toggle", { detail: { isOpen } }))
  }

  onTabClick(event) {
    const tabBtn = event.target.closest("[data-tab]")
    if (!tabBtn) return

    // 少し遅延させて状態を確認
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

    console.log("[plan-time-toggle] closeIfNotPlan")
  }

  isPlanActive() {
    const planbar = document.querySelector(this.planbarSelectorValue)
    if (!planbar) return false

    const planBtn = planbar.querySelector('[data-tab="plan"]')
    return !!planBtn && planBtn.classList.contains("active")
  }
}