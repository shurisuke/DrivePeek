// app/javascript/controllers/plan_tab/departure_time_controller.js
// ================================================================
// DepartureTimeController
// 用途: 出発ブロックの「出発時間」をホイールピッカーで入力し、
//       変更時にAPIで保存する
// ================================================================

import { Controller } from "@hotwired/stimulus"
import { patchTurboStream } from "services/navibar_api"

export default class extends Controller {
  static targets = ["trigger"]
  static values = { planId: Number, current: String }

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
    const existingPicker = document.getElementById("time-wheel-picker")
    if (existingPicker) existingPicker.remove()

    // 現在の値をパース
    let currentHour = 9
    let currentMinute = 0
    if (this.currentValue) {
      const parts = this.currentValue.split(":")
      if (parts.length === 2) {
        currentHour = parseInt(parts[0], 10) || 0
        currentMinute = parseInt(parts[1], 10) || 0
      }
    }

    // ピッカーモーダルを作成
    const dialog = document.createElement("dialog")
    dialog.id = "time-wheel-picker"
    dialog.className = "time-wheel-picker"

    // 時間オプション (0-23)
    const hourOptions = Array.from({ length: 24 }, (_, i) =>
      `<div class="time-wheel-picker__item" data-value="${i}">${String(i).padStart(2, "0")}</div>`
    ).join("")

    // 分オプション (0, 5, 10, ... 55)
    const minuteOptions = Array.from({ length: 12 }, (_, i) =>
      `<div class="time-wheel-picker__item" data-value="${i * 5}">${String(i * 5).padStart(2, "0")}</div>`
    ).join("")

    dialog.innerHTML = `
      <div class="time-wheel-picker__content">
        <div class="time-wheel-picker__header">
          <span class="time-wheel-picker__title">出発時間</span>
          <button type="button" class="time-wheel-picker__header-confirm">完了</button>
        </div>
        <div class="time-wheel-picker__body">
          <div class="time-wheel-picker__wheels">
            <div class="time-wheel-picker__wheel" data-type="hour">
              <div class="time-wheel-picker__scroll">
                ${hourOptions}
              </div>
            </div>
            <div class="time-wheel-picker__colon">:</div>
            <div class="time-wheel-picker__wheel" data-type="minute">
              <div class="time-wheel-picker__scroll">
                ${minuteOptions}
              </div>
            </div>
          </div>
          <div class="time-wheel-picker__highlight"></div>
        </div>
        <div class="time-wheel-picker__footer">
          <button type="button" class="time-wheel-picker__confirm">完了</button>
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
      minuteWheel.scrollTop = Math.round(currentMinute / 5) * itemHeight
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

    // 完了ボタン（フッター + ヘッダー両方）
    const onConfirm = () => {
      const hour = getSelectedValue(hourWheel)
      const minute = getSelectedValue(minuteWheel)
      const timeStr = `${String(hour).padStart(2, "0")}:${String(minute).padStart(2, "0")}`

      dialog.close()
      dialog.remove()

      this._save(timeStr)
    }
    dialog.querySelector(".time-wheel-picker__confirm").addEventListener("click", onConfirm)
    dialog.querySelector(".time-wheel-picker__header-confirm").addEventListener("click", onConfirm)

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
  async _save(timeStr) {
    if (!timeStr || !this.planIdValue) return

    try {
      await patchTurboStream(`/plans/${this.planIdValue}/start_point`, {
        start_point: { departure_time: timeStr },
      })
      // 保存成功 → turbo_stream で navibar が自動更新される
    } catch (e) {
      console.error("[start-departure-time] save error", e)
    }
  }
}
