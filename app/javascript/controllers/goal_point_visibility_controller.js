// app/javascript/controllers/goal_point_visibility_controller.js
//
// ================================================================
// GoalPoint Visibility（単一責務）
// 用途: 帰宅地点の「表示/非表示」をトグルで管理し、
//       - トグルON: 帰宅地点ブロックを表示 + 帰宅地点ピンを描画
//       - トグルOFF: 帰宅地点ブロックを非表示 + 帰宅地点ピンを消す
//
// 追加:
// - 「最後のスポットのトグル」を、帰宅地点がOFFのときは非表示にし
//   帰宅地点がONのときは表示する（DOMは消さず hidden 制御）
//
// 修正:
// - 「最後のスポット判定」をERB/DBではなくDOM基準に変更（Turbo更新/並び替えに強くする）
// - planbar差し替え後にも再適用するため planbar:updated を購読
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

    // ✅ planbar差し替えのたびに「最後スポットのトグル状態」を再適用する
    this._onPlanbarUpdated = () => {
      const v = this.switchTarget.checked
      this.toggleLastSpotDetail(v)
    }
    document.addEventListener("planbar:updated", this._onPlanbarUpdated)

    this.apply(visible, { reason: "connect" })
  }

  disconnect() {
    document.removeEventListener("planbar:updated", this._onPlanbarUpdated)
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
      console.log(
        "[goal-point-visibility] set #map.dataset.goalPointVisible",
        mapEl.dataset.goalPointVisible
      )
    } else {
      console.warn("[goal-point-visibility] #map not found (pin refresh skipped)")
    }

    // ✅ 最後のスポットのトグル表示を切り替える（DOM基準）
    this.toggleLastSpotDetail(visible)

    // ピンを再評価（ONなら描画、OFFなら消える）
    this.refreshGoalPin()
  }

  // ================================================================
  // ✅ 最後のスポットのトグルを、帰宅地点ONのときだけ表示
  // - 「最後」はDOM順（=ユーザーが見ている順）で判定する
  // - 並び替え/追加/Turbo更新に強い
  // ================================================================
  toggleLastSpotDetail(visible) {
    const blocks = document.querySelectorAll(".spot-block[data-plan-spot-id]")
    if (!blocks || blocks.length === 0) {
      console.log("[goal-point-visibility] no spot blocks. skip last toggle")
      return
    }

    const lastBlock = blocks[blocks.length - 1]
    const lastDetailWrap = lastBlock.querySelector(".spot-detail-wrap")

    if (!lastDetailWrap) {
      console.log("[goal-point-visibility] last spot detail-wrap not found")
      return
    }

    lastDetailWrap.hidden = !visible
    console.log("[goal-point-visibility] last spot toggle", { visible })
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