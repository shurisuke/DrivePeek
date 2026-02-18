import { Controller } from "@hotwired/stimulus"

// ================================================================
// SortDropdownController
// 用途: ソート順選択のドロップダウンUI
// - トグルで展開/閉じる
// - オプション選択でフォーム送信
// ================================================================

export default class extends Controller {
  static targets = ["toggle", "menu", "input", "label"]

  connect() {
    // 外部クリックで閉じる
    this.boundClose = this.closeOnOutsideClick.bind(this)
    document.addEventListener("click", this.boundClose)
  }

  disconnect() {
    document.removeEventListener("click", this.boundClose)
  }

  toggle(event) {
    event.stopPropagation()
    this.menuTarget.hidden = !this.menuTarget.hidden
    this.toggleTarget.classList.toggle("is-open", !this.menuTarget.hidden)
  }

  select(event) {
    const value = event.currentTarget.dataset.value
    const label = event.currentTarget.textContent.trim()

    // hidden input 更新
    this.inputTarget.value = value

    // ラベル更新
    this.labelTarget.textContent = label

    // アクティブ状態更新
    this.menuTarget.querySelectorAll(".sort-dropdown__option").forEach(opt => {
      opt.classList.toggle("is-active", opt.dataset.value === value)
    })

    // メニューを閉じる
    this.menuTarget.hidden = true
    this.toggleTarget.classList.remove("is-open")

    // フォーム送信
    const form = document.getElementById("community-search-form")
    if (form) form.requestSubmit()
  }

  closeOnOutsideClick(event) {
    if (!this.element.contains(event.target)) {
      this.menuTarget.hidden = true
      this.toggleTarget.classList.remove("is-open")
    }
  }
}
