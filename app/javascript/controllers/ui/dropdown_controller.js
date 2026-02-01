import { Controller } from "@hotwired/stimulus"

// 汎用ドロップダウンメニュー
export default class extends Controller {
  static targets = ["menu"]

  connect() {
    this.boundClose = this.closeOnClickOutside.bind(this)
  }

  toggle() {
    if (this.menuTarget.hidden) {
      this.open()
    } else {
      this.close()
    }
  }

  open() {
    this.menuTarget.hidden = false
    // 外部クリックで閉じる
    setTimeout(() => {
      document.addEventListener("click", this.boundClose)
    }, 0)
  }

  close() {
    this.menuTarget.hidden = true
    document.removeEventListener("click", this.boundClose)
  }

  closeOnClickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.close()
    }
  }

  disconnect() {
    document.removeEventListener("click", this.boundClose)
  }
}
