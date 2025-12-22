// app/javascript/controllers/navibar_controller.js
//
// ================================================================
// Navibar（単一責務）
// 用途: プラン作成画面のタブ切替 + Planタブ時の時計FAB表示 + 時間表示の一括ON/OFF
// 補足: switch() の既存挙動を壊さず、Plan以外では時間表示を必ず閉じる
// ================================================================

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "content", "timeToggle"]

  connect() {
    console.log("[navibar] connect", {
      hasTimeToggleTarget: this.hasTimeToggleTarget,
      buttons: this.buttonTargets.map((b) => ({ tab: b.dataset.tab, active: b.classList.contains("active") }))
    })

    this.syncTimeToggleVisibility()
    this.closeTimePanelIfNotPlan()
  }

  switch(event) {
    const selected = event.currentTarget.dataset.tab
    console.log("[navibar] switch", { selected })

    // ボタンの active 状態を切り替え
    this.buttonTargets.forEach((btn) => btn.classList.remove("active"))
    event.currentTarget.classList.add("active")

    // コンテンツの表示切り替え
    this.contentTargets.forEach((content) => {
      content.classList.remove("active")
      if (content.classList.contains(`tab-${selected}`)) {
        content.classList.add("active")
      }
    })

    // ✅ Planタブの時だけ時計を表示
    this.syncTimeToggleVisibility()

    // ✅ Plan以外に切り替えたら時間表示は閉じる
    this.closeTimePanelIfNotPlan()
  }

  // ✅ 時計アイコン：全部まとめてON/OFF
  toggleTimePanel() {
    console.log("[navibar] toggleTimePanel clicked")

    if (!this.isPlanActive()) {
      console.log("[navibar] toggleTimePanel aborted (not plan tab)")
      return
    }

    document.body.classList.toggle("plan-time-open")
    const isOpen = document.body.classList.contains("plan-time-open")

    console.log("[navibar] plan-time-open", { isOpen })

    if (this.hasTimeToggleTarget) {
      this.timeToggleTarget.classList.toggle("is-active", isOpen)
      this.timeToggleTarget.setAttribute("aria-pressed", String(isOpen))
    }
  }

  // --------------------
  // private
  // --------------------
  isPlanActive() {
    const planBtn = this.buttonTargets.find((b) => b.dataset.tab === "plan")
    return !!planBtn && planBtn.classList.contains("active")
  }

  syncTimeToggleVisibility() {
    if (!this.hasTimeToggleTarget) {
      console.log("[navibar] syncTimeToggleVisibility skipped (no target)")
      return
    }

    const shouldShow = this.isPlanActive()
    this.timeToggleTarget.hidden = !shouldShow

    console.log("[navibar] syncTimeToggleVisibility", { shouldShow })
  }

  closeTimePanelIfNotPlan() {
    if (this.isPlanActive()) return

    document.body.classList.remove("plan-time-open")

    if (this.hasTimeToggleTarget) {
      this.timeToggleTarget.classList.remove("is-active")
      this.timeToggleTarget.setAttribute("aria-pressed", "false")
    }

    console.log("[navibar] closeTimePanelIfNotPlan")
  }
}