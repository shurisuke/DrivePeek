// app/javascript/controllers/update_memo_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["detail", "editor", "textarea", "memoDisplay", "memoContent"]
  static values = { url: String }

  open(event) {
    event.preventDefault()

    // ① spotDetail を開く（閉じてたら）
    this._showCollapse(this.detailTarget)

    // ② メモエディタを開く
    this._showCollapse(this.editorTarget)

    // ③ フォーカス
    window.setTimeout(() => this.textareaTarget.focus(), 150)
  }

  close(event) {
    event.preventDefault()
    this._hideCollapse(this.editorTarget)
  }

  async submit(event) {
    event.preventDefault()

    const memo = this.textareaTarget.value

    const token = document.querySelector('meta[name="csrf-token"]')?.content

    const res = await fetch(this.urlValue, {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "X-CSRF-Token": token
      },
      body: JSON.stringify({ plan_spot: { memo } })
    })

    if (!res.ok) {
      const err = await res.json().catch(() => ({}))
      alert(err.message || "メモの保存に失敗しました")
      return
    }

    const data = await res.json()

    // 表示更新（改行も反映したいので memo_html を使う）
    this.memoContentTarget.innerHTML = data.memo_html

    // 空なら非表示、あるなら表示
    if (data.memo_present) {
      this.memoDisplayTarget.classList.remove("d-none")
    } else {
      this.memoDisplayTarget.classList.add("d-none")
    }

    // エディタは閉じる（好みで）
    this._hideCollapse(this.editorTarget)
  }

  _showCollapse(element) {
    const Collapse = window.bootstrap?.Collapse
    if (!Collapse) {
      element.classList.add("show")
      return
    }
    Collapse.getOrCreateInstance(element, { toggle: false }).show()
  }

  _hideCollapse(element) {
    const Collapse = window.bootstrap?.Collapse
    if (!Collapse) {
      element.classList.remove("show")
      return
    }
    Collapse.getOrCreateInstance(element, { toggle: false }).hide()
  }
}