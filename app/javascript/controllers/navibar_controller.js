// app/javascript/controllers/navibar_controller.js
//
// ================================================================
// Navibar（単一責務）
// 用途: プラン作成画面のタブ切替のみ
// ================================================================

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "content", "footer"]

  connect() {
    // 外部からタブ切替を要求するイベントを購読
    this.handleActivateTab = this.handleActivateTab.bind(this)
    document.addEventListener("navibar:activate-tab", this.handleActivateTab)

    // 初期状態のフッターを設定
    this.initializeFooter()
  }

  initializeFooter() {
    const activeTabName = this.getActiveTabName()
    this.footerTargets.forEach((footer) => {
      const isActive = footer.dataset.tab === activeTabName
      footer.classList.toggle("is-hidden", !isActive)
    })
  }

  // Turbo Stream でフッターが追加された時に呼ばれる
  footerTargetConnected(footer) {
    const activeTabName = this.getActiveTabName()
    const isActive = footer.dataset.tab === activeTabName
    footer.classList.toggle("is-hidden", !isActive)
  }

  getActiveTabName() {
    const activeTab = this.buttonTargets.find((btn) => btn.classList.contains("active"))
    return activeTab?.dataset.tab || "plan"
  }

  disconnect() {
    document.removeEventListener("navibar:activate-tab", this.handleActivateTab)
  }

  handleActivateTab(event) {
    const tabName = event.detail?.tab
    if (!tabName) return
    this.activateTab(tabName)
  }

  activateTab(tabName) {
    // ボタンの active 状態を切り替え
    this.buttonTargets.forEach((btn) => {
      btn.classList.toggle("active", btn.dataset.tab === tabName)
    })

    // コンテンツの表示切り替え
    this.contentTargets.forEach((content) => {
      content.classList.remove("active")
      if (content.classList.contains(`tab-${tabName}`)) {
        content.classList.add("active")
      }
    })

    // フッターの表示切り替え（アクションボタンも含む）
    this.footerTargets.forEach((footer) => {
      const isActive = footer.dataset.tab === tabName
      footer.classList.toggle("is-hidden", !isActive)
    })
  }

  switch(event) {
    const selected = event.currentTarget.dataset.tab
    this.activateTab(selected)
  }
}
