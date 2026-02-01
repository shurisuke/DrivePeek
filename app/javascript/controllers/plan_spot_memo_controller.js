// app/javascript/controllers/plan_spot_memo_controller.js
import { Controller } from "@hotwired/stimulus"
import { patch } from "services/api_client"

export default class extends Controller {
  static targets = ["detail", "editor", "textarea", "memoDisplay", "memoContent"]
  static values = { url: String }

  connect() {
    // ✅ トグル収納時にメモエディタを閉じる
    this._onCollapseHide = this._onCollapseHide.bind(this)
    if (this.hasDetailTarget) {
      this.detailTarget.addEventListener("hide.bs.collapse", this._onCollapseHide)
    }
  }

  disconnect() {
    if (this.hasDetailTarget) {
      this.detailTarget.removeEventListener("hide.bs.collapse", this._onCollapseHide)
    }
  }

  _onCollapseHide() {
    this.closeIfOpen()
  }

  stopPropagation(event) {
    event.stopPropagation()
  }

  focusTextarea(event) {
    if (event) {
      event.preventDefault()
      event.stopPropagation()
    }
    this.textareaTarget.focus()
  }

  focusTextareaToEnd() {
    const el = this.textareaTarget
    el.focus()

    const len = el.value.length
    try {
      el.setSelectionRange(len, len)
    } catch (_) {}
  }

  open(event) {
    event.preventDefault()

    // ✅ メモを開く前に「他を閉じて」と通知（相互排他）
    this.element.dispatchEvent(new CustomEvent("spot:memo-opened", { bubbles: true }))

    // ① spotDetail を開く（閉じてたら）
    this._showCollapse(this.detailTarget)

    // ② メモエディタを表示
    this.editorTarget.classList.remove("d-none")

    // ③ 既存メモは「表示したまま」
    // this.memoDisplayTarget.classList.add("d-none")

    // ④ 編集中フラグ：削除ボタン表示用
    this.memoDisplayTarget.classList.add("is-editing")

    // ⑤ 初回フォーカス（末尾へ）
    window.setTimeout(() => this.focusTextareaToEnd(), 0)
  }

  close(event) {
    if (event) event.preventDefault()
    this.closeIfOpen()
  }

  closeIfOpen() {
    if (!this.hasEditorTarget) return
    if (this.editorTarget.classList.contains("d-none")) return

    this.editorTarget.classList.add("d-none")
    this.memoDisplayTarget.classList.remove("is-editing")

    if (this.memoContentTarget?.innerText?.trim() !== "") {
      this.memoDisplayTarget.classList.remove("d-none")
    }
  }

  async submit(event) {
    event.preventDefault()

    const memo = this.textareaTarget.value
    const data = await this._patchMemo(memo)
    if (!data) return

    this.memoContentTarget.innerHTML = data.memo_html

    if (data.memo_present) {
      this.memoDisplayTarget.classList.remove("d-none")
    } else {
      this.memoDisplayTarget.classList.add("d-none")
    }

    this.memoDisplayTarget.classList.remove("is-editing")
    this.editorTarget.classList.add("d-none")
  }

  async clear(event) {
    event.stopPropagation()

    const data = await this._patchMemo("")
    if (!data) return

    this.textareaTarget.value = ""
    this.memoContentTarget.innerHTML = ""
    this.memoDisplayTarget.classList.add("d-none")
    this.memoDisplayTarget.classList.remove("is-editing")
    this.editorTarget.classList.add("d-none")
  }

  async _patchMemo(memo) {
    try {
      return await patch(this.urlValue, { memo })
    } catch (error) {
      alert(error.message || "メモの保存に失敗しました")
      return null
    }
  }

  _showCollapse(element) {
    const Collapse = window.bootstrap?.Collapse
    if (!Collapse) {
      element.classList.add("show")
      return
    }
    Collapse.getOrCreateInstance(element, { toggle: false }).show()
  }
}