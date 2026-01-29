import { Controller } from "@hotwired/stimulus"

// ================================================================
// AiActionButtonsController
// 用途: AI提案のモード選択・アクションボタン制御
// - 初期モード選択（プラン提案/スポット提案）
// - 応答後アクション（エリア選び直し/条件変更/質問）
// ================================================================

export default class extends Controller {
  static values = {
    mode: String,        // "plan" | "spots"
    area: Object,        // { center_lat, center_lng, radius_km }
    condition: Object,   // { slot_count, slots: [...] }
  }

  // ============================================
  // 初期モード選択
  // ============================================

  // エリアからプランを提案
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

  // 条件を変更（既存エリア・条件保持）
  changeCondition() {
    document.dispatchEvent(new CustomEvent("ai:openConditionModal", {
      detail: {
        mode: this.modeValue,
        area: this.areaValue,
        condition: this.conditionValue
      }
    }))
    console.log("[ai_action_buttons] openConditionModal:", this.modeValue)
  }

  // ============================================
  // Private
  // ============================================

  #dispatchAreaDraw(mode, options = {}) {
    document.dispatchEvent(new CustomEvent("ai:startAreaDraw", {
      detail: { mode, ...options }
    }))
    console.log("[ai_action_buttons] startAreaDraw:", mode, options)
  }
}
