import { Controller } from "@hotwired/stimulus"

// ================================================================
// SuggestModeController
// 用途: 提案モード選択・アクションボタン制御
// - 初期モード選択（プラン提案/スポット提案）
// - 応答後アクション（エリア選び直し/条件変更/終了）
// ================================================================

export default class extends Controller {
  static values = {
    mode: String,        // "plan" | "spots"
    area: Object,        // { center_lat, center_lng, radius_km }
    condition: Object,   // { slot_count, slots: [...] }
    planId: Number,      // プランID（終了API用）
  }

  // ============================================
  // 初期モード選択
  // ============================================

  // まるっとプラン提案
  startPlanMode() {
    this.#dispatchAreaDraw("plan")
  }

  // エリアからスポットを提案
  startSpotMode() {
    this.#dispatchAreaDraw("spots")
  }

  // ============================================
  // 応答後アクション
  // ============================================

  // エリアを選び直す（既存条件保持）
  reselectArea() {
    this.#dispatchAreaDraw(this.modeValue, {
      condition: this.conditionValue
    })
  }

  // 条件を変更（同じエリアで再度モーダルを開く）
  changeCondition() {
    const area = this.areaValue || {}
    document.dispatchEvent(new CustomEvent("ai:areaSelected", {
      detail: {
        mode: this.modeValue,
        center_lat: area.center_lat,
        center_lng: area.center_lng,
        radius_km: area.radius_km
      }
    }))
  }

  // 終了（モード選択UIを再表示）
  async finish() {
    try {
      const response = await fetch(`/api/ai_area/finish?plan_id=${this.planIdValue}`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Accept": "text/vnd.turbo-stream.html",
          "X-CSRF-Token": this.#csrfToken
        }
      })

      if (!response.ok && response.status !== 204) throw new Error("API error")

      const text = await response.text()
      if (text) Turbo.renderStreamMessage(text)
    } catch (error) {
      console.error("[SuggestMode] finish error:", error)
    }
  }

  // ============================================
  // Private
  // ============================================

  get #csrfToken() {
    return document.querySelector("meta[name='csrf-token']")?.content || ""
  }

  #dispatchAreaDraw(mode, options = {}) {
    document.dispatchEvent(new CustomEvent("ai:startAreaDraw", {
      detail: { mode, ...options }
    }))
  }
}
