// app/javascript/controllers/myroute_tab/spot_memo_controller.js
// ================================================================
// SpotMemoController
// 用途: スポットブロック内のメモ編集UI
//   - メモの表示/編集切り替え
//   - トグル収納時に自動でエディタを閉じる
//   - turbo_stream経由でサーバーがUI更新
// ================================================================

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["detail", "editor", "textarea", "memoDisplay", "memoContent"]

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

    // ① spotDetail を開く（閉じてたら）
    this._showCollapse(this.detailTarget)

    // ② メモエディタを表示
    this.editorTarget.classList.remove("d-none")

    // ③ 編集中フラグ：削除ボタン表示用
    this.memoDisplayTarget.classList.add("is-editing")

    // ④ 初回フォーカス（末尾へ）
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

  // turbo:submit-end イベントハンドラ（フォーム送信完了後）
  onSubmitEnd(event) {
    if (!event.detail.success) return

    // エディタを閉じる
    this.editorTarget.classList.add("d-none")
    this.memoDisplayTarget.classList.remove("is-editing")

    // メモ表示の更新はturbo_streamで行われるため、ここでは閉じるだけ
  }

  // メモをクリアしてフォーム送信（削除ボタン用）
  clearAndSubmit(event) {
    event.preventDefault()
    this.textareaTarget.value = ""
    this.textareaTarget.form.requestSubmit()
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
