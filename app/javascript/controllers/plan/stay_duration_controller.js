// app/javascript/controllers/spot_stay_duration_controller.js
// ================================================================
// Spot Stay Duration Controller（単一責務）
// 用途: スポットブロックの「滞在時間」をiOS風ホイールピッカーで入力し、
//       変更時にAPIで保存する
// ================================================================

import { Controller } from "@hotwired/stimulus"
import { patchTurboStream } from "services/api_client"

export default class extends Controller {
  static targets = ["trigger"]
  static values = { planId: Number, planSpotId: Number, current: Number }

  connect() {
    // 初期化処理があれば追加
  }

  disconnect() {
    // クリーンアップ処理があれば追加
  }

  // トリガーボタンクリックでピッカーを開く
  openPicker(event) {
    event.preventDefault()
    this._showWheelPicker()
  }

  // ============================
  // Wheel Picker
  // ============================
  _showWheelPicker() {
    // 既存のピッカーがあれば削除
    const existingPicker = document.getElementById("stay-duration-wheel-picker")
    if (existingPicker) existingPicker.remove()

    // 現在の値をパース（分）
    const currentMinutes = this.currentValue || 0
    const currentHour = Math.floor(currentMinutes / 60)
    const currentMinute = currentMinutes % 60

    // ピッカーモーダルを作成
    const dialog = document.createElement("dialog")
    dialog.id = "stay-duration-wheel-picker"
    dialog.className = "time-wheel-picker"

    // 時間オプション (0-12時間)
    const hourOptions = Array.from({ length: 13 }, (_, i) =>
      `<div class="time-wheel-picker__item" data-value="${i}">${i}</div>`
    ).join("")

    // 分オプション (0, 10, 20, 30, 40, 50)
    const minuteOptions = [0, 10, 20, 30, 40, 50].map((m) =>
      `<div class="time-wheel-picker__item" data-value="${m}">${String(m).padStart(2, "0")}</div>`
    ).join("")

    dialog.innerHTML = `
      <div class="time-wheel-picker__content">
        <div class="time-wheel-picker__header">
          <button type="button" class="time-wheel-picker__cancel">キャンセル</button>
          <span class="time-wheel-picker__title">滞在時間</span>
          <button type="button" class="time-wheel-picker__confirm">完了</button>
        </div>
        <div class="time-wheel-picker__body">
          <div class="time-wheel-picker__wheels">
            <div class="time-wheel-picker__wheel" data-type="hour">
              <div class="time-wheel-picker__scroll">
                ${hourOptions}
              </div>
            </div>
            <div class="time-wheel-picker__unit">時間</div>
            <div class="time-wheel-picker__wheel" data-type="minute">
              <div class="time-wheel-picker__scroll">
                ${minuteOptions}
              </div>
            </div>
            <div class="time-wheel-picker__unit">分</div>
          </div>
          <div class="time-wheel-picker__highlight"></div>
        </div>
      </div>
    `

    document.body.appendChild(dialog)

    // 各ホイールのスクロール位置を初期化
    const hourWheel = dialog.querySelector('[data-type="hour"] .time-wheel-picker__scroll')
    const minuteWheel = dialog.querySelector('[data-type="minute"] .time-wheel-picker__scroll')
    const itemHeight = 40 // CSSで定義する高さと合わせる

    // 初期位置にスクロール
    setTimeout(() => {
      hourWheel.scrollTop = currentHour * itemHeight
      // 10分刻み: 0→0, 10→1, 20→2, 30→3, 40→4, 50→5
      minuteWheel.scrollTop = Math.round(currentMinute / 10) * itemHeight
    }, 10)

    // 選択値を取得するヘルパー
    const getSelectedValue = (wheel) => {
      const scrollTop = wheel.scrollTop
      const index = Math.round(scrollTop / itemHeight)
      const items = wheel.querySelectorAll(".time-wheel-picker__item")
      if (items[index]) {
        return parseInt(items[index].dataset.value, 10)
      }
      return 0
    }

    // キャンセルボタン
    dialog.querySelector(".time-wheel-picker__cancel").addEventListener("click", () => {
      dialog.close()
      dialog.remove()
    })

    // 完了ボタン
    dialog.querySelector(".time-wheel-picker__confirm").addEventListener("click", () => {
      const hour = getSelectedValue(hourWheel)
      const minute = getSelectedValue(minuteWheel)
      const totalMinutes = hour * 60 + minute

      dialog.close()
      dialog.remove()

      this._save(totalMinutes)
    })

    // 背景クリックで閉じる
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
  async _save(minutes) {
    if (!this.planSpotIdValue) return

    try {
      await patchTurboStream(
        `/api/plan_spots/${this.planSpotIdValue}`,
        { stay_duration: minutes }
      )
      // 保存成功 → turbo_stream で navibar が自動更新される
    } catch (e) {
      console.error("[spot-stay-duration] save error", e)
    }
  }
}
