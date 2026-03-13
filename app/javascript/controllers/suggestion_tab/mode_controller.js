import { Controller } from "@hotwired/stimulus"
import { getMapInstance, clearSuggestionAll, setSuggestionAreaCircle } from "map/state"
import { fitBoundsWithPadding } from "map/visual_center"
import { postTurboStream } from "services/navibar_api"
import { AREA_CIRCLE_STYLES } from "map/constants"

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

  // エリアを選び直す
  reselectArea() {
    clearSuggestionAll()
    this.#dispatchAreaDraw(this.modeValue)
  }

  // 条件を変更（同じエリアで再度モーダルを開く）
  changeCondition() {
    const adjusted = this.#getBottomSheetController()?.adjustToMid() || false

    const execute = () => {
      clearSuggestionAll()
      const area = this.areaValue || {}

      // 同じエリアで円を再描画してズーム
      this.#drawAreaCircle(area)

      document.dispatchEvent(new CustomEvent("suggestion:areaSelected", {
        detail: {
          center_lat: area.center_lat,
          center_lng: area.center_lng,
          radius_km: area.radius_km
        }
      }))
    }

    if (adjusted) {
      // ボトムシートのアニメーション完了後に円を描画（地図の表示範囲が確定してから）
      setTimeout(execute, 320)
    } else {
      execute()
    }
  }

  // エリア円を描画してズーム（グロー効果付き）
  #drawAreaCircle(area) {
    const map = getMapInstance()
    if (!map || !area.center_lat || !area.center_lng || !area.radius_km) return

    const center = { lat: area.center_lat, lng: area.center_lng }
    const radius = area.radius_km * 1000
    const { shadow } = AREA_CIRCLE_STYLES
    const layers = AREA_CIRCLE_STYLES.suggestion

    const circles = [
      // 影（ぼかし効果）
      new google.maps.Circle({
        map,
        center,
        radius: radius + shadow.offset,
        strokeColor: shadow.color,
        strokeWeight: shadow.weight,
        strokeOpacity: shadow.opacity,
        fillOpacity: 0,
        clickable: false,
        zIndex: 0
      }),
      // グラデーション風の縁
      ...layers.map((layer, i) => new google.maps.Circle({
        map,
        center,
        radius: radius + layer.offset,
        strokeColor: layer.color,
        strokeWeight: i === layers.length - 1 ? 2 : 3,
        strokeOpacity: layer.opacity,
        fillOpacity: 0,
        clickable: false,
        zIndex: i + 1
      }))
    ]

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

  #getBottomSheetController() {
    const navibar = document.querySelector("[data-controller~='ui--bottom-sheet']")
    if (!navibar) return null
    return this.application.getControllerForElementAndIdentifier(navibar, "ui--bottom-sheet")
  }
}
