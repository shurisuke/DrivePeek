// app/javascript/controllers/plan_save_modal_controller.js
// ================================================================
// プラン保存モーダル: ボタンクリックでモーダルを表示
// モーダルは動的に生成してbodyに追加（HTML構造の問題を回避）
// ================================================================

import { Controller } from "@hotwired/stimulus"
import { patch } from "services/api_client"

export default class extends Controller {
  static values = { planId: Number, title: String }

  open() {
    this.removeExistingModal()
    this.modal = this.createModal()
    document.body.appendChild(this.modal)
    document.body.classList.add("plan-save-modal-open")

    // 入力欄にフォーカス（カーソルを末尾に配置）
    const input = this.modal.querySelector(".plan-save-modal__input")
    if (input) {
      input.focus()
      input.setSelectionRange(input.value.length, input.value.length)
    }
  }

  close() {
    this.removeExistingModal()
    document.body.classList.remove("plan-save-modal-open")
  }

  removeExistingModal() {
    const existing = document.querySelector(".plan-save-modal")
    if (existing) existing.remove()
  }

  createModal() {
    const modal = document.createElement("div")
    modal.className = "plan-save-modal"
    modal.innerHTML = `
      <div class="plan-save-modal__overlay"></div>
      <div class="plan-save-modal__dialog">
        <p class="plan-save-modal__message">名前をつけてプランを保存してください</p>
        <input
          type="text"
          class="form-control plan-save-modal__input"
          placeholder="プラン名を入力"
          value="${this.titleValue || ""}"
        >
        <p class="plan-save-modal__error" hidden>プラン名を入力してください</p>
        <div class="plan-save-modal__actions">
          <button type="button" class="btn btn-cancel">キャンセル</button>
          <button type="button" class="btn btn-primary">保存</button>
        </div>
      </div>
    `

    // イベントリスナー
    modal.querySelector(".plan-save-modal__overlay").addEventListener("click", () => this.close())
    modal.querySelector(".btn-cancel").addEventListener("click", () => this.close())
    modal.querySelector(".btn-primary").addEventListener("click", () => this.save())
    modal.querySelector(".plan-save-modal__input").addEventListener("keydown", (e) => {
      if (e.key === "Enter") this.save()
    })

    return modal
  }

  async save() {
    const input = this.modal.querySelector(".plan-save-modal__input")
    const errorEl = this.modal.querySelector(".plan-save-modal__error")
    const title = input.value.trim()

    if (!title) {
      errorEl.hidden = false
      input.focus()
      return
    }

    errorEl.hidden = true

    try {
      const data = await patch(`/plans/${this.planIdValue}`, { plan: { title } })

      if (data.success) {
        this.close()
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
    const errorEl = this.modal?.querySelector(".plan-save-modal__error")
    if (errorEl) {
      errorEl.textContent = message
      errorEl.hidden = false
    }
  }

  showSuccessMessage() {
    // 保存完了の簡易フィードバック
    console.log("[plan-save-modal] saved successfully")
  }
}
