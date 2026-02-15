// app/javascript/controllers/plan/spot_delete_controller.js
import { Controller } from "@hotwired/stimulus"
import { removeSpotFromPlan } from "services/navibar_api"

export default class extends Controller {
  static values = {
    planId: Number,
    planSpotId: Number,
  }

  async delete(event) {
    event.preventDefault()

    // 1. 即座にDOMから削除（Optimistic UI）
    // 対応する時刻レールブロックも削除
    const timeRailBlock = document.querySelector(
      `.time-rail-block--spot[data-plan-spot-id="${this.planSpotIdValue}"]`
    )
    if (timeRailBlock) timeRailBlock.remove()

    this.element.remove()

    // 2. 即座にマーカー再描画（番号更新含む）
    document.dispatchEvent(new CustomEvent("navibar:updated"))

    // 3. 距離表示をスケルトン化
    document.querySelectorAll(".spot-next-move").forEach((el) => {
      el.classList.add("is-calculating")
    })

    // 4. バックグラウンドでAPI呼び出し
    try {
      await removeSpotFromPlan(this.planSpotIdValue, this.planIdValue)
    } catch (error) {
      console.error("[spot_delete] Error:", error)
      alert("削除に失敗しました。ページを再読み込みしてください。")
    }
  }
}
