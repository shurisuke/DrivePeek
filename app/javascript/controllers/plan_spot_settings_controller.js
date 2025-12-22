// app/javascript/controllers/plan_spot_settings_controller.js
//
// ================================================================
// Plan Spot Settings（単一責務）
// 用途: スポットブロックの「設定フォーム」を開閉する
//  - タグ/メモと同様に spot-detail 内で表示（d-none切替）
//  - 開いたら、同ブロック内のタグフォーム/メモフォームは閉じる
// ================================================================

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel", "toggle"]

  toggle() {
    const isHidden = this.panelTarget.classList.contains("d-none")
    if (isHidden) {
      this.open()
    } else {
      this.close()
    }
  }

  open() {
    // 他フォームを閉じる（存在すれば）
    this.closeOtherPanels()

    this.panelTarget.classList.remove("d-none")
    if (this.hasToggleTarget) this.toggleTarget.setAttribute("aria-expanded", "true")
  }

  close() {
    this.panelTarget.classList.add("d-none")
    if (this.hasToggleTarget) this.toggleTarget.setAttribute("aria-expanded", "false")
  }

  stopPropagation(e) {
    e.stopPropagation()
  }

  closeOtherPanels() {
    // plan-spot-tags
    try {
      const tags = this.application.getControllerForElementAndIdentifier(this.element, "plan-spot-tags")
      if (tags?.close) tags.close()
    } catch (_) {}

    // plan-spot-memo
    try {
      const memo = this.application.getControllerForElementAndIdentifier(this.element, "plan-spot-memo")
      if (memo?.close) memo.close()
    } catch (_) {}
  }
}