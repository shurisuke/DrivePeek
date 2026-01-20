import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "counter"]
  static values = { maxLength: { type: Number, default: 100 } }

  connect() {
    this.updateCounter()
    this.autoResize()
  }

  updateCounter() {
    const current = this.inputTarget.value.length
    const max = this.maxLengthValue
    const remaining = max - current

    this.counterTarget.textContent = `${current}/${max}`

    // 残り20文字以下で警告色
    if (remaining <= 20) {
      this.counterTarget.classList.add("dp-infowindow__comment-counter--warning")
    } else {
      this.counterTarget.classList.remove("dp-infowindow__comment-counter--warning")
    }

    // 残り0文字で赤
    if (remaining <= 0) {
      this.counterTarget.classList.add("dp-infowindow__comment-counter--limit")
    } else {
      this.counterTarget.classList.remove("dp-infowindow__comment-counter--limit")
    }
  }

  autoResize() {
    const textarea = this.inputTarget
    // 一旦高さをリセットしてscrollHeightを正確に取得
    textarea.style.height = "auto"
    // scrollHeightに合わせて高さを設定（最大3行程度）
    const maxHeight = 72 // 約3行分
    const newHeight = Math.min(textarea.scrollHeight, maxHeight)
    textarea.style.height = `${newHeight}px`
  }
}
