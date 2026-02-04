import { Controller } from "@hotwired/stimulus"
import { closeInfoWindow } from "map/infowindow"
import { addSpotToPlan, removeSpotFromPlan } from "services/api_client"

// InfoWindow内のスポット追加・削除ボタン用
export default class extends Controller {
  static values = {
    spotId: Number,
    planId: Number,
    planSpotId: Number,
    method: { type: String, default: "POST" },
  }

  async submit(event) {
    event.preventDefault()

    this.startLoading()

    try {
      if (this.methodValue === "DELETE") {
        closeInfoWindow()
        await removeSpotFromPlan(this.planSpotIdValue, this.planIdValue)
      } else {
        await addSpotToPlan(this.planIdValue, this.spotIdValue)
      }
      // 成功時はボタンが置き換わるのでローディング解除不要
    } catch (error) {
      console.error("[infowindow_spot_action] Error:", error)
      alert("操作に失敗しました")
      this.stopLoading()
    }
  }

  startLoading() {
    this.originalText = this.element.textContent
    this.element.classList.add("dp-infowindow__btn--loading")
    this.element.textContent = this.methodValue === "POST" ? "追加中..." : "削除中..."
    this.element.disabled = true
  }

  stopLoading() {
    this.element.classList.remove("dp-infowindow__btn--loading")
    this.element.textContent = this.originalText
    this.element.disabled = false
  }
}
