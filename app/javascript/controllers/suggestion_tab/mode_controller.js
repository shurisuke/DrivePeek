import { Controller } from "@hotwired/stimulus"
import { getMapInstance, clearSuggestionMarkers, setSuggestionAreaCircle } from "map/state"
import { fitBoundsWithPadding } from "map/visual_center"
import { postTurboStream } from "services/navibar_api"

// ================================================================
// SuggestModeController
// 用途: 提案モード選択・アクションボタン制御
// - 初期モード選択（まるっとプラン提案）
// - 応答後アクション（エリア選び直し/条件変更/終了）
// ================================================================

export default class extends Controller {
  static values = {
    mode: String,        // "plan"
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

  // エリア円を描画してズーム（グロー効果付き）
  #drawAreaCircle(area) {
    const map = getMapInstance()
    if (!map || !area.center_lat || !area.center_lng || !area.radius_km) return

    const center = { lat: area.center_lat, lng: area.center_lng }
    const radius = area.radius_km * 1000
    const circles = []

    // 影（ぼかし効果）
    const shadow = new google.maps.Circle({
      map,
      center,
      radius: radius + 20,
      strokeColor: "#000",
      strokeWeight: 12,
      strokeOpacity: 0.08,
      fillOpacity: 0,
      clickable: false,
      zIndex: 0
    })
    circles.push(shadow)

    // グラデーション風の太い縁（外側から内側へ色を重ねる）
    const strokeLayers = [
      { offset: 8, color: "#764ba2", opacity: 0.3 },  // 外側：紫
      { offset: 4, color: "#7164c0", opacity: 0.5 },  // 中間
      { offset: 0, color: "#667eea", opacity: 0.9 },  // 内側：青紫
    ]

    strokeLayers.forEach((layer, index) => {
      const c = new google.maps.Circle({
        map,
        center,
        radius: radius + layer.offset,
        strokeColor: layer.color,
        strokeWeight: index === strokeLayers.length - 1 ? 2 : 3,
        strokeOpacity: layer.opacity,
        fillOpacity: 0,
        clickable: false,
        zIndex: index + 1
      })
      circles.push(c)
    })

    setSuggestionAreaCircle(circles)
    fitBoundsWithPadding(circles[circles.length - 1].getBounds())
  }

  // 終了（モード選択UIを再表示）
  async finish() {
    try {
      await postTurboStream("/suggestions/finish", { plan_id: this.planIdValue })
    } catch (error) {
      console.error("[SuggestMode] finish error:", error)
    }
  }

  // ============================================
  // Private
  // ============================================

  #dispatchAreaDraw(mode, options = {}) {
    document.dispatchEvent(new CustomEvent("ui:startAreaDraw", {
      detail: { mode, ...options }
    }))
  }
}
