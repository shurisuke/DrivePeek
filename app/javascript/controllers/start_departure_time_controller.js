// app/javascript/controllers/start_departure_time_controller.js
// ================================================================
// Start Departure Time Controller（単一責務）
// 用途: 出発ブロックの「出発時間」入力に flatpickr(time only) を適用し、
//       変更時にAPIで保存する
// 前提: Turbo Frame で navibar が差し替わっても、connect で確実に再初期化される
// ================================================================

import { Controller } from "@hotwired/stimulus"
import flatpickr from "flatpickr"
import { patchTurboStream } from "services/api_client"

export default class extends Controller {
  static targets = ["input"]
  static values = { planId: Number }

  connect() {
    if (!this.hasInputTarget) return

    // 既に適用済みなら何もしない（Turboの再接続で二重適用を防ぐ）
    if (this.inputTarget.dataset.fpApplied === "1") return
    this.inputTarget.dataset.fpApplied = "1"

    // 手入力が 900 みたいになっても、blurで整形＆保存
    this.inputTarget.addEventListener("blur", this._onBlur)

    // flatpickr 適用（time only）- 入力欄クリックでピッカーが開く
    this._fp = flatpickr(this.inputTarget, {
      enableTime: true,
      noCalendar: true,
      time_24hr: true,
      dateFormat: "H:i",
      allowInput: true,
      minuteIncrement: 5,
      clickOpens: true,
      disableMobile: true,
      appendTo: document.body,
      onOpen: () => {
        const normalized = this._normalizeTimeText(this.inputTarget.value)
        if (normalized) this.inputTarget.value = normalized
      },
      onClose: (_selectedDates, dateStr) => {
        // ピッカーを閉じたときに保存（三角ボタン操作中は保存しない）
        if (dateStr) this._save(dateStr)
      },
    })
  }

  disconnect() {
    // Turbo差し替え時に破棄しておく（メモリリーク/イベント残り防止）
    try {
      this.inputTarget?.removeEventListener("blur", this._onBlur)
    } catch (_) {}

    try {
      this._fp?.destroy()
    } catch (_) {}

    this._fp = null
  }

  showHelp(event) {
    event.preventDefault()
    event.stopPropagation()
    this._showHelpDialog()
  }

  _showHelpDialog() {
    // 既存のダイアログがあれば削除
    const existingDialog = document.getElementById("departure-time-help-dialog")
    if (existingDialog) existingDialog.remove()

    // 出発時間が設定済みかどうかで内容を分岐
    const isSet = this.element.classList.contains("start-departure-time--set")

    const title = isSet
      ? "時間の変更"
      : "時間を設定してみよう"

    const text = isSet
      ? `時刻をクリックして出発時間を設定できます。<br>
         追加したスポットの下の🔽で滞在時間も入れてみてください。予定がもっとリアルに組めます。`
      : `このアプリでは、出発時間や滞在時間を設定することで、<br>
         より現実に近いタイムスケジュールを組むことができます。<br>
         まずは試しに、出発時間を設定してみましょう。`

    const dialog = document.createElement("dialog")
    dialog.id = "departure-time-help-dialog"
    dialog.innerHTML = `
      <div class="departure-time-help-dialog__content">
        <h3 class="departure-time-help-dialog__title">${title}</h3>
        <p class="departure-time-help-dialog__text">${text}</p>
        <button type="button" class="departure-time-help-dialog__close-btn">OK</button>
      </div>
    `
    document.body.appendChild(dialog)

    const closeBtn = dialog.querySelector(".departure-time-help-dialog__close-btn")
    closeBtn.addEventListener("click", () => {
      dialog.close()
      dialog.remove()
    })

    dialog.addEventListener("click", (e) => {
      if (e.target === dialog) {
        dialog.close()
        dialog.remove()
      }
    })

    dialog.showModal()
  }

  // ============================
  // private
  // ============================
  _onBlur = () => {
    if (!this.hasInputTarget) return
    // ピッカーが開いている間はblur保存をスキップ（onCloseで処理）
    if (this._fp?.isOpen) return

    const normalized = this._normalizeTimeText(this.inputTarget.value)
    if (normalized) {
      this.inputTarget.value = normalized
      this._save(normalized)
    }
  }

  async _save(timeStr) {
    if (!timeStr || !this.planIdValue) return

    try {
      await patchTurboStream(`/api/plans/${this.planIdValue}/start_point`, {
        start_point: { departure_time: timeStr },
      })
      // 保存成功 → turbo_stream で navibar が自動更新される
    } catch (e) {
      console.error("[start-departure-time] save error", e)
    }
  }

  _normalizeTimeText(raw) {
    if (!raw) return ""
    const s = String(raw).trim()

    // すでに 09:00 形式ならそのまま
    if (/^\d{1,2}:\d{2}$/.test(s)) {
      const [h, m] = s.split(":").map((x) => Number(x))
      if (Number.isFinite(h) && Number.isFinite(m)) {
        return `${String(h).padStart(2, "0")}:${String(m).padStart(2, "0")}`
      }
      return s
    }

    // 900 / 0900 / 9 などを 09:00 に寄せる
    const digits = s.replace(/[^\d]/g, "")
    if (digits.length === 1) return `0${digits}:00`
    if (digits.length === 2) return `${digits}:00`
    if (digits.length === 3) return `0${digits.slice(0, 1)}:${digits.slice(1)}`
    if (digits.length >= 4) return `${digits.slice(0, 2)}:${digits.slice(2, 4)}`

    return ""
  }
}
