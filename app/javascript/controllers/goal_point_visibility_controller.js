// app/javascript/controllers/goal_point_visibility_controller.js
//
// ================================================================
// GoalPoint Visibility（単一責務）
// 用途: 帰宅地点の「表示/非表示」をトグルで管理し、
//       - トグルON: 帰宅地点ブロックを表示 + 帰宅地点ピンを描画
//       - トグルOFF: 帰宅地点ブロックを非表示 + 帰宅地点ピンを消す
//
// 仕様:
// - 帰宅地点は plan 作成時点でDB上に存在している前提（=ここでは作成しない）
// - 表示状態は sessionStorage に plan_id ごとに保存して、Turbo更新でも復元する
// - デバッグ用に console.log を多めに出す
// ================================================================

import { Controller } from "@hotwired/stimulus"
import { getPlanDataFromPage } from "map/plan_data"

export default class extends Controller {
  static targets = ["switch", "blockArea"]
  static values = { planId: Number }

  connect() {
    console.log("[goal-point-visibility] connect", {
      planId: this.planIdValue,
      hasSwitch: this.hasSwitchTarget,
      hasBlockArea: this.hasBlockAreaTarget,
    })

    // 初期値: 保存済みがあれば復元 / なければ OFF
    const saved = sessionStorage.getItem(this.storageKey())
    const visible = saved === "true"

    this.switchTarget.checked = visible
    this.apply(visible, { reason: "connect" })
  }

  toggle() {
    const visible = this.switchTarget.checked
    console.log("[goal-point-visibility] toggle", { visible })

    sessionStorage.setItem(this.storageKey(), String(visible))
    this.apply(visible, { reason: "toggle" })
  }

  apply(visible, { reason } = {}) {
    console.log("[goal-point-visibility] apply", { visible, reason })

    // ブロック表示切り替え
    this.blockAreaTarget.hidden = !visible

    // 地図側（描画条件）に「今ONか」を伝える（render_plan_markers が参照）
    const mapEl = document.getElementById("map")
    if (mapEl) {
      mapEl.dataset.goalPointVisible = visible ? "true" : "false"
      console.log("[goal-point-visibility] set #map.dataset.goalPointVisible", mapEl.dataset.goalPointVisible)
    } else {
      console.warn("[goal-point-visibility] #map not found (pin refresh skipped)")
    }

    // ピンを再評価（ONなら描画、OFFなら消える）
    this.refreshGoalPin()
  }

  async refreshGoalPin() {
    try {
      const planData = getPlanDataFromPage()
      console.log("[goal-point-visibility] refreshGoalPin planData", planData)

      const { refreshGoalMarker } = await import("plans/render_plan_markers")
      refreshGoalMarker(planData)

      document.dispatchEvent(
        new CustomEvent("plan:goal-point-visibility-changed", {
          detail: { visible: this.switchTarget.checked, plan_id: this.planIdValue },
        })
      )
    } catch (e) {
      console.error("[goal-point-visibility] refreshGoalPin failed", e)
    }
  }

  storageKey() {
    return `goalPointVisible:${this.planIdValue}`
  }
}