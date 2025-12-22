// app/javascript/controllers/plan_spot_settings_controller.js
//
// ================================================================
// Plan Spot Settings（単一責務）
// 用途: スポットブロックの「設定フォーム」を開閉する
//  - タグ/メモと相互排他（どれかが開いたら他は閉じる）
// ================================================================

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel", "toggle"]

  connect() {
    // ✅ タグ or メモが開いたら、設定は閉じる（相互排他）
    this._onTagsOpened = () => this.closeIfOpen()
    this._onMemoOpened = () => this.closeIfOpen()

    this.element.addEventListener("spot:tags-opened", this._onTagsOpened)
    this.element.addEventListener("spot:memo-opened", this._onMemoOpened)
  }

  disconnect() {
    this.element.removeEventListener("spot:tags-opened", this._onTagsOpened)
    this.element.removeEventListener("spot:memo-opened", this._onMemoOpened)
  }

  toggle(event) {
    if (event) event.preventDefault()

    const isHidden = this.panelTarget.classList.contains("d-none")
    if (isHidden) {
      this.open()
    } else {
      this.close()
    }
  }

  open() {
    // ✅ 設定を開く前に「設定が開くよ」を通知（相互排他）
    this.element.dispatchEvent(new CustomEvent("spot:settings-opened", { bubbles: true }))

    // 念のため：既存の直接呼び出しでも閉じる（イベント方式と二重でもOK）
    this.closeOtherPanels()

    this.panelTarget.classList.remove("d-none")
    if (this.hasToggleTarget) this.toggleTarget.setAttribute("aria-expanded", "true")
  }

  close(event) {
    if (event) event.preventDefault()

    this.panelTarget.classList.add("d-none")
    if (this.hasToggleTarget) this.toggleTarget.setAttribute("aria-expanded", "false")
  }

  closeIfOpen() {
    if (!this.hasPanelTarget) return
    if (this.panelTarget.classList.contains("d-none")) return
    this.close()
  }

  stopPropagation(e) {
    e.stopPropagation()
  }

  closeOtherPanels() {
    // plan-spot-tags
    try {
      const tags = this.application.getControllerForElementAndIdentifier(this.element, "plan-spot-tags")
      if (tags?.closeIfOpen) tags.closeIfOpen()
      else if (tags?.close) tags.close()
    } catch (_) {}

    // plan-spot-memo
    try {
      const memo = this.application.getControllerForElementAndIdentifier(this.element, "plan-spot-memo")
      if (memo?.closeIfOpen) memo.closeIfOpen()
      else if (memo?.close) memo.close()
    } catch (_) {}
  }
}