// app/javascript/controllers/plan_spot_tags_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["chips", "form", "input"]

  connect() {
    // ✅ メモが開いたら、タグ側を閉じる（相互排他）
    this._onMemoOpened = () => this.closeIfOpen()
    this.element.addEventListener("spot:memo-opened", this._onMemoOpened)

    // ✅ タグチップが Turbo で再描画されたら、編集モード表示を復元する
    this._onFrameRender = () => this.syncEditingUI()
    if (this.hasChipsTarget) {
      this.chipsTarget.addEventListener("turbo:frame-render", this._onFrameRender)
    }

    this.syncEditingUI()
  }

  disconnect() {
    this.element.removeEventListener("spot:memo-opened", this._onMemoOpened)

    if (this.hasChipsTarget) {
      this.chipsTarget.removeEventListener("turbo:frame-render", this._onFrameRender)
    }
  }

  toggle(event) {
    event.preventDefault()

    const willOpen = this.formTarget.classList.contains("d-none")

    if (willOpen) {
      // ✅ タグを開く前に「他を閉じて」と通知（相互排他）
      this.element.dispatchEvent(new CustomEvent("spot:tags-opened", { bubbles: true }))

      this.formTarget.classList.remove("d-none")
      this.syncEditingUI()

      window.setTimeout(() => {
        if (this.hasInputTarget) this.inputTarget.focus()
      }, 0)
    } else {
      this.closeIfOpen()
    }
  }

  close(event) {
    if (event) event.preventDefault()
    this.closeIfOpen()
  }

  closeIfOpen() {
    if (!this.hasFormTarget) return
    if (this.formTarget.classList.contains("d-none")) return

    this.formTarget.classList.add("d-none")
    this.syncEditingUI()
  }

  stopPropagation(event) {
    event.stopPropagation()
  }

  // ✅ 送信後：成功したら入力欄の“色付き原因”を掃除して、フォームは開いたまま
  afterSubmit(event) {
    if (!event.detail?.success) return
    if (!this.hasInputTarget) return

    this.inputTarget.value = ""
    this.inputTarget.classList.remove("is-valid", "is-invalid")

    this.inputTarget.blur()
    window.setTimeout(() => this.inputTarget.focus(), 0)

    this.syncEditingUI()
  }

  syncEditingUI() {
    if (!this.hasChipsTarget || !this.hasFormTarget) return
    const editing = !this.formTarget.classList.contains("d-none")
    this.chipsTarget.classList.toggle("is-editing", editing)
  }
}