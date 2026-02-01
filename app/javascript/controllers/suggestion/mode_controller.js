import { Controller } from "@hotwired/stimulus"
import { getMapInstance, clearSuggestionMarkers, setSuggestionAreaCircle } from "map/state"

// ================================================================
// SuggestModeController
// 用途: 提案モード選択・アクションボタン制御
// - 初期モード選択（まるっとプラン提案/かこんでスポット検索）
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

  // かこんでスポット検索
  startSpotMode() {
    this.#dispatchAreaDraw("spots")
  }

  // ============================================
  // 応答後アクション
  // ============================================

  // エリアを選び直す（既存条件保持）
  reselectArea() {
    clearSuggestionMarkers()
    this.#dispatchAreaDraw(this.modeValue, {
      condition: this.conditionValue
    })
  }

  // 条件を変更（同じエリアで再度モーダルを開く）
  changeCondition() {
    clearSuggestionMarkers()
    const area = this.areaValue || {}

    // 同じエリアで円を再描画してズーム
    this.#drawAreaCircle(area)

    document.dispatchEvent(new CustomEvent("suggestion:areaSelected", {
      detail: {
        mode: this.modeValue,
        center_lat: area.center_lat,
        center_lng: area.center_lng,
        radius_km: area.radius_km
      }
    }))
  }

  // エリア円を描画してズーム
  #drawAreaCircle(area) {
    const map = getMapInstance()
    if (!map || !area.center_lat || !area.center_lng || !area.radius_km) return

    const circle = new google.maps.Circle({
      map: map,
      center: { lat: area.center_lat, lng: area.center_lng },
      radius: area.radius_km * 1000,
      strokeColor: "#667eea",
      strokeWeight: 2,
      fillColor: "#667eea",
      fillOpacity: 0.03,
      clickable: false
    })

    setSuggestionAreaCircle(circle)
    map.fitBounds(circle.getBounds())
  }

  // 終了（モード選択UIを再表示）
  async finish() {
    try {
      const response = await fetch(`/suggestions/finish?plan_id=${this.planIdValue}`, {
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
    document.dispatchEvent(new CustomEvent("suggestion:startAreaDraw", {
      detail: { mode, ...options }
    }))
  }
}
