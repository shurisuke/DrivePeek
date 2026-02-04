// app/javascript/controllers/plan/spot_delete_controller.js
import { Controller } from "@hotwired/stimulus"
import { removeSpotFromPlan } from "services/api_client"

export default class extends Controller {
  static values = {
    planId: Number,
    planSpotId: Number,
  }

  async delete(event) {
    event.preventDefault()

    try {
      await removeSpotFromPlan(this.planSpotIdValue, this.planIdValue)
    } catch (error) {
      console.error("[spot_delete] Error:", error)
      alert("削除に失敗しました")
    }
  }
}
