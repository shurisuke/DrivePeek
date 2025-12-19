// app/javascript/controllers/plan_spot_memo_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["detail", "editor", "textarea", "memoDisplay", "memoContent"]
  static values = { url: String }

  // ✅ textarea / 削除ボタン上での pointerdown/click を親へ伝播させない
  stopPropagation(event) {
    event.stopPropagation()
  }

  // ✅ textarea にフォーカスするだけ（カーソル位置は触らない）
  focusTextarea(event) {
    if (event) {
      event.preventDefault()
      event.stopPropagation()
    }
    this.textareaTarget.focus()
  }

  // ✅ open直後だけ末尾へ（ここだけ selectionRange を使う）
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

    // ① spotDetail を開く（閉じてたら）
    this._showCollapse(this.detailTarget)

    // ② メモエディタを表示
    this.editorTarget.classList.remove("d-none")

    // ③ 既存メモがある場合は入力中は非表示
    this.memoDisplayTarget.classList.add("d-none")

    // ④ 初回フォーカス（末尾へ）
    window.setTimeout(() => this.focusTextareaToEnd(), 0)
  }

  close(event) {
    event.preventDefault()

    // エディタ非表示
    this.editorTarget.classList.add("d-none")

    // 既存メモがあるなら再表示
    if (this.memoContentTarget.innerText.trim() !== "") {
      this.memoDisplayTarget.classList.remove("d-none")
    }
  }

  async submit(event) {
    event.preventDefault()

    const memo = this.textareaTarget.value
    const data = await this._patchMemo(memo)
    if (!data) return

    // 表示更新（改行反映のため memo_html）
    this.memoContentTarget.innerHTML = data.memo_html

    // ✅ 保存したらメモブロックの表示を解禁
    if (data.memo_present) {
      this.memoDisplayTarget.classList.remove("d-none")
    } else {
      this.memoDisplayTarget.classList.add("d-none")
    }

    // エディタは閉じる
    this.editorTarget.classList.add("d-none")
  }

  // ✅ 追加：削除（= 空文字で update）
  async clear(event) {
    event.stopPropagation()

    const data = await this._patchMemo("")
    if (!data) return

    // textarea も空に
    this.textareaTarget.value = ""

    // 表示も消す
    this.memoContentTarget.innerHTML = ""
    this.memoDisplayTarget.classList.add("d-none")

    // エディタ閉じる
    this.editorTarget.classList.add("d-none")
  }

  async _patchMemo(memo) {
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
      return null
    }

    return await res.json()
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