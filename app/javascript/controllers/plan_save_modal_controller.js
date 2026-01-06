// app/javascript/controllers/plan_save_modal_controller.js
// ================================================================
// 単一責務: プラン保存モーダルの表示/非表示と保存処理
// ================================================================

import { Controller } from "@hotwired/stimulus"
import { patch } from "services/api_client"

export default class extends Controller {
  static targets = ["modal", "input", "error"]
  static values = { planId: Number }

  open() {
    this.modalTarget.hidden = false
    this.errorTarget.hidden = true
    this.inputTarget.value = ""
    this.inputTarget.focus()
  }

  close() {
    this.modalTarget.hidden = true
    this.errorTarget.hidden = true
    this.inputTarget.value = ""
  }

  async save() {
    const title = this.inputTarget.value.trim()

    if (!title) {
      this.errorTarget.hidden = false
      this.inputTarget.focus()
      return
    }

    this.errorTarget.hidden = true

    try {
      const data = await patch(`/plans/${this.planIdValue}`, { plan: { title } })

      if (data.success) {
        this.close()
        // 保存成功のフィードバック（シンプルに通知）
        this.showSuccessMessage()
      } else {
        this.showError(data.errors?.join(", ") || "保存に失敗しました")
      }
    } catch (error) {
      console.error("[plan-save-modal] save failed:", error)
      this.showError("保存に失敗しました")
    }
  }

  showError(message) {
    this.errorTarget.textContent = message
    this.errorTarget.hidden = false
  }

  showSuccessMessage() {
    // 簡易的な保存完了表示（ボタンのテキストを一時的に変更）
    const saveBtn = this.element.querySelector(".btn-save")
    if (saveBtn) {
      const originalText = saveBtn.textContent
      saveBtn.textContent = "保存しています…"
      saveBtn.disabled = true
      setTimeout(() => {
        saveBtn.textContent = originalText
        saveBtn.disabled = false
      }, 2000)
    }
  }
}
